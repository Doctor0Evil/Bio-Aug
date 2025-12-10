use anyhow::Context;
use serde_json::json;
use std::fs::File;
use std::io::Read;

pub fn extract_traceability(path: &str) -> anyhow::Result<serde_json::Value> {
    let mut s = String::new();
    File::open(path)?.read_to_string(&mut s)?;
    let mut policies = Vec::new();
    for part in s.split("policy ") {
        if !part.contains("traceability") { continue; }
        // quick extract: find 'policy <ident>' then traceability block
        let name = part.split_whitespace().next().unwrap_or("unknown");
        let tr_start = part.find("traceability").unwrap();
        let tr_end = part[tr_start..].find("end").unwrap_or(0)+tr_start;
        let tr_block = &part[tr_start..tr_end+3.min(part.len()-tr_start)];
        let mut hazard_id = ""; let mut iec = "";
        for line in tr_block.lines() {
            if line.contains("hazard_id") { hazard_id = line.split(':').nth(1).unwrap_or("").trim_matches(|c: char| c=='"' || c==' '); }
            if line.contains("iec62304_class") { iec = line.split(':').nth(1).unwrap_or("").trim_matches(|c: char| c=='"' || c==' '); }
        }
        policies.push(json!({"policy": name, "hazard_id": hazard_id, "iec62304_class": iec}));
    }
    Ok(json!({"file": path, "policies": policies}))
}
