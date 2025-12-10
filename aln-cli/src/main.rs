use structopt::StructOpt;
use std::path::PathBuf;
use std::path::Path;
use anyhow::Context;
use aln_syntax::parse_aln;
use aln_check::validate_aln;
use aln_check::coverage_check;
use csv;
mod traceability;

#[derive(StructOpt)]
enum Cmd {
    Parse {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
    },
    Validate {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, default_value = "bioaug-clinical")]
        profile: String,
        #[structopt(long)]
        require_dpia: bool,
        #[structopt(long)]
        require_dos_guard: bool,
        #[structopt(long)]
        fail_if_unverified_class_c: bool,
    },
    Codegen {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, default_value = "rust")]
        target: String,
        #[structopt(long, parse(from_os_str))]
        out: PathBuf,
    },
    Trace {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
    },
    #[structopt(name = "check-coverage")]
    CheckCoverage {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, parse(from_os_str))]
        out_csv: PathBuf,
        #[structopt(long, parse(from_os_str))]
        out_proof: PathBuf,
    },
    #[structopt(name = "trace-export")]
    TraceExport {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, parse(from_os_str))]
        out_csv: PathBuf,
    },
    #[structopt(name = "trace-sign")]
    TraceSign {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, parse(from_os_str))]
        out: PathBuf,
        #[structopt(long)]
        signing_profile: Option<String>,
    },
    #[structopt(name = "zero-trust-validate")]
    ZeroTrustValidate {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long)]
        segment: Option<String>,
    },
    ZeroTrustValidate {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long, default_value = "bioaug-clinical")]
        profile: String,
        #[structopt(long)]
        segment: Option<String>,
    },
}

fn main() -> anyhow::Result<()> {
    let cmd = Cmd::from_args();
    match cmd {
        Cmd::Parse { input } => {
            let s = std::fs::read_to_string(&input)?;
            let _pairs = parse_aln(&s).context("parse error")?;
            println!("parse OK: {}", input.display());
        }
        Cmd::Validate { input, profile } => {
            let s = std::fs::read_to_string(&input)?;
            // pass DPIA/DoS guard flags
            aln_check::validate_aln(&s, &profile, require_dpia, require_dos_guard).context("validation error")?;
            if fail_if_unverified_class_c {
                // Ensure Class C policies have traceability and required fields
                let pols = aln_check::coverage_check as fn(&str, &std::path::Path, &std::path::Path) -> anyhow::Result<()>;
                // Simplified: we'll run semantic_check and check for Class C traceability via validate_aln_strict
                aln_check::validate_aln_strict(&s, &profile).context("class-c verification failed")?;
            }
            // For bioaug-clinical, require an ALN signature sidecar and verify both CLINICAL_POLICY and SECURITY_POLICY
            if profile == "bioaug-clinical" {
                let sig_path = input.with_extension("sig.json");
                if !sig_path.exists() {
                    anyhow::bail!("bioaug-clinical requires ALN sidecar signature ({}.sig.json)", input.display());
                }
                // Verify using tools/signer-rs binary if present in repo
                let signer_bin = std::path::Path::new("tools/signer-rs/target/release/signer-rs");
                if signer_bin.exists() {
                    use std::process::Command;
                    let status = Command::new(signer_bin)
                        .args(["verify", "--input", input.to_str().unwrap(), "--keyref", "ci/keys/bgc_root.pub", "--expect-profile", "CLINICAL_POLICY"])
                        .status()?;
                    if !status.success() { anyhow::bail!("ALN validation failed: CLINICAL_POLICY signature verification failed") }
                    let status2 = Command::new(signer_bin)
                        .args(["verify", "--input", input.to_str().unwrap(), "--keyref", "ci/keys/bgc_root.pub", "--expect-profile", "SECURITY_POLICY"])
                        .status()?;
                    if !status2.success() { anyhow::bail!("ALN validation failed: SECURITY_POLICY signature verification failed") }
                } else {
                    println!("Warning: signer binary not found, skipping ALN signature verification but requiring sidecar presence");
                }
            }
            println!("validate OK: {} (profile={})", input.display(), profile);
            }
            Cmd::Codegen { input, target, out } => {
                let s = std::fs::read_to_string(&input)?;
                // run basic validation first
                aln_check::validate_aln_strict(&s, "bioaug-clinical").context("validation error")?;
                if target == "rust" {
                    aln_codegen::generate_rust_stub(&s, out.to_str().unwrap()).context("gen error")?;
                } else if target == "wasm" {
                    aln_codegen::generate_wasm(&s, out.to_str().unwrap()).context("gen error")?;
                } else {
                    println!("Codegen target not implemented: {}", target);
                }
                println!("codegen OK: {} -> {} ({})", input.display(), out.display(), target);
        }
            Cmd::Trace { input } => {
                let res = traceability::extract_traceability(input.to_str().unwrap())?;
            println!("{}", serde_json::to_string_pretty(&res)?);
        }
            Cmd::CheckCoverage { input, out_csv, out_proof } => {
                let s = std::fs::read_to_string(&input)?;
                coverage_check(&s, Path::new(&out_csv), Path::new(&out_proof)).context("coverage check failed")?;
                println!("coverage check OK -> {} {}", out_csv.display(), out_proof.display());
            }
            Cmd::TraceExport { input, out_csv } => {
                let res = traceability::extract_traceability(input.to_str().unwrap())?;
                let csv_path = out_csv.clone();
                // Minimal export: write CSV with policy, hazard_id, iec class
                let mut w = csv::Writer::from_path(csv_path)?;
                w.write_record(&["policy","hazard_id","iec62304_class"])?;
                if let serde_json::Value::Object(map) = &res {
                    if let Some(serde_json::Value::Array(pols)) = map.get("policies") {
                        for p in pols.iter() {
                            if let (Some(policy), Some(hazard_id), Some(iec)) = (
                                p.get("policy"), p.get("hazard_id"), p.get("iec62304_class")
                            ) {
                                w.write_record(&[policy.as_str().unwrap_or(""), hazard_id.as_str().unwrap_or(""), iec.as_str().unwrap_or("")])?;
                            }
                        }
                    }
                }
                w.flush()?;
                println!("trace exported to {}", out_csv.display());
            }
            Cmd::TraceSign { input, out, signing_profile } => {
                        }
                        Cmd::ZeroTrustValidate { input, segment } => {
                            let s = std::fs::read_to_string(&input)?;
                            // Basic zero-trust checks: microsegmentation, rbac, anomaly detectors present
                            if !s.to_lowercase().contains("microsegmentation") { anyhow::bail!("zero-trust validate: missing microsegmentation rule"); }
                            if !s.to_lowercase().contains("rbac") { anyhow::bail!("zero-trust validate: missing rbac rule"); }
                            if !s.to_lowercase().contains("anomaly") && !s.to_lowercase().contains("detectors") { anyhow::bail!("zero-trust validate: missing anomaly detector rules"); }
                            println!("zero-trust validate OK: {} segment={:?}", input.display(), segment);
                        }
                        Cmd::ZeroTrustValidate { input, profile, segment } => {
                            let s = std::fs::read_to_string(&input)?;
                            // Basic checks: microsegmentation, rbac, anomaly_detection
                            if !s.contains("microsegmentation") && !s.contains("micro-segmentation") {
                                anyhow::bail!("ZeroTrust: missing microsegmentation policy");
                            }
                            if !s.contains("rbac") && !s.contains("role") {
                                anyhow::bail!("ZeroTrust: missing RBAC policy");
                            }
                            if !s.contains("anomaly_detection") && !s.contains("anomaly-detector") {
                                anyhow::bail!("ZeroTrust: missing anomaly detection policy");
                            }
                            println!("ZeroTrust validate OK: {} (profile={}) seg={:?}", input.display(), profile, segment);
                        }
                // Use local signer to sign CSV; fallback to printing
                let signer_bin = std::path::Path::new("tools/signer-rs/target/release/signer-rs");
                if signer_bin.exists() {
                    use std::process::Command;
                    let mut cmd = Command::new(signer_bin);
                    cmd.args(["sign", "--input", input.to_str().unwrap(), "--profile", signing_profile.as_deref().unwrap_or("CLINICAL_POLICY"), "--output", out.to_str().unwrap()]);
                    let status = cmd.status()?;
                    if !status.success() { anyhow::bail!("trace sign failed") }
                    println!("trace signed ok -> {}", out.display());
                } else {
                    println!("signer not found; writing unsigned trace to {}", out.display());
                    std::fs::copy(&input, &out)?;
                }
            }
    }
    Ok(())
}
