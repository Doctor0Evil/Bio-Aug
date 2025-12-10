use anyhow::Result;
use aln_syntax::parse_aln;
use std::path::Path;
use std::fs::File;
use std::io::Write;
use serde_json::json;
use csv::Writer;
use std::collections::HashSet;

pub fn validate_aln(content: &str, profile: &str, require_dpia: bool, require_dos_guard: bool) -> Result<()> {
    // Basic validation: parse then run simple checks
    let pairs = parse_aln(content).map_err(|e| anyhow::anyhow!("parse error: {}", e))?;
    // TODO: implement AST builder and semantic checks
    println!("Parsed pairs: {:?}", pairs.clone().count());
    // Minimal checks: look for 'aln' top-level decls
    if !content.contains("aln") { return Err(anyhow::anyhow!("no top-level 'aln' found")); }
    // Basic profile application (placeholder)
    if profile == "bioaug-clinical" {
        if !content.contains("policy") {
            return Err(anyhow::anyhow!("bioaug-clinical requires at least one policy"));
        }
        // Find policies that affect actuation and ensure they include traceability annotations
        let policy_blocks: Vec<&str> = content.split("policy").collect();
        for pb in policy_blocks.iter().skip(1) {
            let block = pb;
            // Heuristic: if block explicitly declares IEC class C, require traceability fields
            if block.to_lowercase().contains("iec62304_class") && (block.contains("iec62304_class: \"C\"") || block.contains("iec62304_class: C")) {
                if !block.contains("traceability") {
                    return Err(anyhow::anyhow!("BioAugClinical: Class C policy must include a 'traceability' block"));
                }
                // Required traceability fields per IEC/ISO mapping: hazard_id, iso14971_clause, iec62304_class, rationale
                let required = ["hazard_id", "iso14971_clause", "iec62304_class", "rationale"];
                for field in required.iter() {
                    if !block.contains(field) {
                        return Err(anyhow::anyhow!(format!("BioAugClinical: Class C traceability missing required field {}", field)));
                    }
                }
                if !block.contains("iec62304_class: \"C\"") && !block.contains("iec62304_class: C") {
                    return Err(anyhow::anyhow!("BioAugClinical: iec62304_class must be 'C' for Class C policies"));
                }
            }
            // Heuristic: if the block mentions actuation, require traceability
            if block.to_lowercase().contains("actuat") || block.to_lowercase().contains("implant") || block.to_lowercase().contains("invasive") {
                if !block.contains("traceability") {
                    return Err(anyhow::anyhow!("BioAugClinical: policy affecting actuation/implant/invasive must include a 'traceability' block"));
                }
                // Required traceability fields per IEC/ISO mapping: hazard_id, iso14971_clause, iec62304_class, rationale
                let required = ["hazard_id", "iso14971_clause", "iec62304_class", "rationale"];
                for field in required.iter() {
                    if !block.contains(field) {
                        return Err(anyhow::anyhow!(format!("BioAugClinical: traceability block missing required field {}", field)));
                    }
                }
                // Ensure the stated IEC class is 'C' for bioaug-clinical
                if !block.contains("iec62304_class: \"C\"") && !block.contains("iec62304_class: C") {
                    return Err(anyhow::anyhow!("BioAugClinical: iec62304_class must be 'C' for actuation/implant/invasive policies"));
                }
            }
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_validate_simple() {
        let s = r#"
        aln system Test {
            policy p {
                // affects actuation
                condition allow when true;
                traceability {
                    hazard_id: "HAZ-001";
                    iso14971_clause: "5.4.2";
                    iec62304_class: "C";
                    rationale: "Mitigates potential hazards by requiring user consent";
                }
            } end policy
        } end system
        "#;
        // Should validate for bioaug-clinical profile
        validate_aln_strict(s, "bioaug-clinical").unwrap_or_else(|e| panic!("validation failed: {}", e));
        // Enforce DPIA requirements: simple heuristic - there must be 'dpia: true' in header or policy tags
        if require_dpia {
            if !content.to_lowercase().contains("dpia") && !content.to_lowercase().contains("data_protection_impact_assessment") {
                return Err(anyhow::anyhow!("BioAugClinical: profile requires DPIA to be specified for policies in this workspace"));
            }
        }
        // Enforce DoS guard presence for agentic/AI policies
        if require_dos_guard {
            if content.to_lowercase().contains("ai") || content.to_lowercase().contains("agent") {
                if !content.to_lowercase().contains("dos_guard") && !content.to_lowercase().contains("rate_limit") && !content.to_lowercase().contains("anomaly_detection") {
                    return Err(anyhow::anyhow!("BioAugClinical: profile requires DoS guard rules (rate_limit, anomaly_detection, sandbox) for AI/agentic policies"));
                }
            }
        }
    }
    #[test]
    fn test_semantic_duplicate_policy_name() {
        let s = r#"
        aln system Test {
            policy p { condition allow when true; traceability { hazard_id: "HAZ-1"; iso14971_clause: "5"; iec62304_class: "C"; rationale: "ok"; } } end policy
            policy p { condition allow when true; traceability { hazard_id: "HAZ-2"; iso14971_clause: "5"; iec62304_class: "C"; rationale: "dup"; } } end policy
        } end system
        "#;
        let res = semantic_check(s);
        assert!(res.is_err());
    }
    #[test]
    fn test_require_dpia() {
        let s = r#"
        aln system Test {
            policy p { condition allow when true; traceability { hazard_id: "HAZ-1"; iso14971_clause: "5"; iec62304_class: "C"; rationale: "ok"; } } end policy
        } end system
        "#;
        let r = validate_aln(s, "bioaug-clinical", true, false);
        assert!(r.is_err());
    }
    Ok(())
}

pub fn validate_aln_strict(content: &str, profile: &str) -> Result<()> {
    // Strict validation wrapper: require DPIA and DoS guard and standard Class C traceability
    validate_aln(content, profile, true, true)?;
    semantic_check(content)?;
    Ok(())
}

pub fn coverage_check(content: &str, out_csv: &Path, out_proof: &Path) -> Result<()> {
    // Heuristic parser: scan for hazard_id and control-id occurrences
    let mut hazards: Vec<String> = Vec::new();
    let mut controls: Vec<String> = Vec::new();
    for line in content.lines() {
        let l = line.trim();
        if l.starts_with("hazard_id") || l.contains("hazard_id:") {
            // parse
            if let Some(v) = l.split(':').nth(1) {
                let id = v.trim_matches(|c: char| c==';' || c=='"').trim().to_string();
                if !id.is_empty() { hazards.push(id); }
            }
        }
        if l.starts_with("control-id") || l.contains("control-id:") {
            if let Some(v) = l.split(':').nth(1) {
                let id = v.trim_matches(|c: char| c==';' || c=='"').trim().to_string();
                if !id.is_empty() { controls.push(id); }
            }
        }
    }
    hazards.sort(); hazards.dedup();
    controls.sort(); controls.dedup();
    // Build simple coverage: any hazard id must appear in controls mapping via policy traceability
    // Heuristic match: if control id references hazard id as suffix or contains hazard id
    let mut matrix: Vec<(String,String)> = Vec::new();
    for h in hazards.iter() {
        let mut covered = false;
        for c in controls.iter() {
            if c.contains(h) || c.ends_with(h) || h.ends_with(c) || h == c { matrix.push((h.clone(), c.clone())); covered = true; }
        }
        if !covered { matrix.push((h.clone(), String::from("<uncovered>"))); }
    }
    // Write CSV
    let mut wtr = Writer::from_path(out_csv)?;
    wtr.write_record(&["hazard", "control"])?;
    for (h,c) in matrix.iter() { wtr.write_record(&[h, c])?; }
    wtr.flush()?;
    // Emit proof JSON
    let nh = hazards.len(); let ncov = matrix.iter().filter(|(_,c)| c != "<uncovered>").count();
    let proof = json!({"Nhazards_total": nh, "Nhazards_with_controls": ncov, "R": (ncov as f64)/(nh as f64)});
    let mut f = File::create(out_proof)?; f.write_all(serde_json::to_string_pretty(&proof)?.as_bytes())?;
    Ok(())
}

pub fn semantic_check(content: &str) -> Result<()> {
    // Name resolution: detect duplicate policy names
    let mut names = HashSet::new();
    for part in content.split("policy ").skip(1) {
        if let Some(name) = part.split_whitespace().next() {
            if names.contains(name) {
                return Err(anyhow::anyhow!(format!("Semantic error: duplicate policy name {}", name)));
            }
            names.insert(name.to_string());
        }
    }
    // Guard-type safety / no dynamic or ambiguous targets: scan for dynamic-like tokens
    let lowered = content.to_lowercase();
    let forbidden = ["dynamic", "load", "syscall", "network", "fs", "exec", "eval", "reflect"];
    for f in forbidden.iter() {
        if lowered.contains(f) {
            return Err(anyhow::anyhow!(format!("Semantic error: forbidden construct '{}' used in policy", f)));
        }
    }
    // Basic guard check: ensure each policy has a condition
    for part in content.split("policy ").skip(1) {
        if !part.contains("condition") && !part.contains("guard") {
            return Err(anyhow::anyhow!("Semantic error: policy missing condition/guard"));
        }
    }
    Ok(())
}