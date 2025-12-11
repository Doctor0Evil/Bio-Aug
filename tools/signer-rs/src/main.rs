use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::PathBuf;
use structopt::StructOpt;
use anyhow::Context;
use ring::signature::{Ed25519KeyPair, KeyPair, VerificationAlgorithm, ED25519};
use ring::signature::UnparsedPublicKey;
use ring::rand::{SystemRandom};
use sha2::{Sha256, Digest};
use serde_yaml::Value;
use base64::{engine::general_purpose, Engine as _};
use std::collections::BTreeMap;
use tar::Builder as TarBuilder;
use flate2::Compression;
use flate2::write::GzEncoder;
use tempfile::NamedTempFile;
use std::process::Command;

#[derive(StructOpt)]
enum Cmd {
    Sign {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long)]
        keyref: Option<String>,
        #[structopt(long)]
        output: Option<PathBuf>,
        #[structopt(long)]
        profile: String,
        #[structopt(long)]
        force: bool,
    },
    Verify {
        #[structopt(parse(from_os_str))]
        input: PathBuf,
        #[structopt(long)]
        keyref: Option<String>,
        #[structopt(long)]
        expect_profile: Option<String>,
    },
    GenerateDevKeys {
        #[structopt(parse(from_os_str))]
        output: PathBuf,
    },
    ExportJwk {
        #[structopt(parse(from_os_str))]
        pubkey: PathBuf,
        #[structopt(long, parse(from_os_str))]
        output: Option<PathBuf>,
    },
}

fn canonicalize_yaml(y: &str) -> anyhow::Result<String> {
    // Parse to serde_yaml::Value then create a canonical string with sorted object keys.
    let v: Value = serde_yaml::from_str(y).context("parse yaml")?;
    let canonical = canonical_yaml_value(&v);
    Ok(canonical)
}

fn canonical_yaml_value(v: &Value) -> String {
    match v {
        Value::Mapping(m) => {
            let mut entries: Vec<(String, String)> = Vec::new();
            for (k, val) in m.iter() {
                let key = format!("{}", k);
                let val_s = canonical_yaml_value(val);
                entries.push((key, val_s));
            }
            entries.sort_by(|a,b| a.0.cmp(&b.0));
            let mut out = String::new();
            out.push_str("{\n");
            for (k, v) in entries.iter() {
                out.push_str(&format!("{}: {},\n", k, v));
            }
            out.push_str("}");
            out
        },
        Value::Sequence(seq) => {
            let mut parts = Vec::new();
            for item in seq.iter() { parts.push(canonical_yaml_value(item)); }
            format!("[{}]", parts.join(","))
        },
        Value::String(s) => format!("\"{}\"", s.replace('\n', "\\n")),
        Value::Bool(b) => format!("{}", b),
        Value::Number(n) => format!("{}", n),
        Value::Null => String::from("null"),
        _ => format!("{:?}", v)
    }
}

fn compute_hash(data: &[u8]) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().to_vec()
}

fn sign_with_keyfile(pkcs8_bytes: &[u8], data: &[u8]) -> anyhow::Result<Vec<u8>> {
    // Sign using Ed25519 keypair loaded from PKCS8
    let keypair = Ed25519KeyPair::from_pkcs8(pkcs8_bytes).context("load keypair from pkcs8")?;
    let sig = keypair.sign(data);
    Ok(sig.as_ref().to_vec())
}

#[cfg(feature = "hsm")]
fn sign_with_hsm(pkcs11_label: &str, pin: &str, module_path: &str, data: &[u8]) -> anyhow::Result<Vec<u8>> {
    use std::process::Command;
    use tempfile::NamedTempFile;
    let mut dataf = NamedTempFile::new()?; dataf.write_all(data)?; let in_path = dataf.path().to_str().unwrap().to_string();
    let out_temp = NamedTempFile::new()?; let out_path = out_temp.path().to_str().unwrap().to_string();
    let module = module_path;
    // Use pkcs11-tool to sign using label and pin; assume key id 01
    let status = Command::new("pkcs11-tool")
        .args(["--module", module, "--login", "--pin", pin, "--sign", "--label", pkcs11_label, "--id", "01", "--input-file", &in_path, "--output-file", &out_path])
        .status()?;
    if !status.success() { anyhow::bail!("pkcs11-tool sign failed") }
    let mut f = File::open(out_path)?; let mut buf = Vec::new(); f.read_to_end(&mut buf)?;
    Ok(buf)
}

#[cfg(feature = "hsm")]
fn export_pubkey_from_hsm(pkcs11_label: &str, pin: &str, module_path: &str, out_file: &str) -> anyhow::Result<()> {
    use std::process::Command;
    // Read object and write public key PEM file using `pkcs11-tool` or `openssl` wrapper
    let status = Command::new("pkcs11-tool")
        .args(["--module", module_path, "--login", "--pin", pin, "--read-object", "--type", "pubkey", "--label", pkcs11_label, "--output-file", out_file])
        .status()?;
    if !status.success() { anyhow::bail!("pkcs11-tool read-public-key failed") }
    Ok(())
}

fn verify_with_pubkey(pubkey_bytes: &[u8], data: &[u8], sig: &[u8]) -> anyhow::Result<bool> {
    let public_key = UnparsedPublicKey::new(&ED25519, pubkey_bytes);
    Ok(public_key.verify(data, sig).is_ok())
}

fn generate_dev_keys(output: &PathBuf) -> anyhow::Result<()> {
    // Generate Ed25519 key pair and write pk8 and pubkey into tar.gz
    let rng = SystemRandom::new();
    let pkcs8 = Ed25519KeyPair::generate_pkcs8(&rng).context("generate pkcs8")?;
    let keypair = Ed25519KeyPair::from_pkcs8(pkcs8.as_ref()).context("create keypair")?;
    let pubkey = keypair.public_key().as_ref();

    let tmp = NamedTempFile::new()?;
    let mut tar_gz = GzEncoder::new(Vec::new(), Compression::default());
    let mut ar = TarBuilder::new(&mut tar_gz);
    ar.append_data(&mut tar::Header::new_gnu(), "dev_pkcs8.key", &mut &pkcs8.as_ref()[..])?;
    ar.append_data(&mut tar::Header::new_gnu(), "dev_pub.key", &mut &pubkey[..])?;
    let gz = tar_gz.finish()?;
    let mut out_f = File::create(output)?;
    out_f.write_all(&gz)?;
    Ok(())
}

fn main() -> anyhow::Result<()> {
    let cmd = Cmd::from_args();
    match cmd {
        Cmd::Sign { input, keyref, output, profile } => {
                    // Read file content and compute hash; support YAML and ALN.
                    let mut f = File::open(&input)?;
                    let mut s = String::new();
                    f.read_to_string(&mut s)?;
                    let h = if input.extension().and_then(|e| e.to_str()) == Some("aln") {
                        // Simple canonicalization: normalize newlines and trim
                        let canonical = s.replace("\r\n", "\n").trim().to_string();
                        compute_hash(canonical.as_bytes())
                    } else {
                        let canonical = canonicalize_yaml(&s)?; compute_hash(canonical.as_bytes())
                    };
            let sig = if let Some(kref) = keyref {
                if kref.starts_with("hsm://") {
                    // hsm://<label>:<pin> - uses pkcs11-tool under the hood
                    #[cfg(feature = "hsm")]
                    {
                        let rest = &kref[6..];
                        let parts: Vec<&str> = rest.split(':').collect();
                        if parts.len() != 2 { anyhow::bail!("Invalid HSM keyref format. expected hsm://label:pin") }
                        let label = parts[0]; let pin = parts[1];
                        let module = std::env::var("PKCS11_MODULE").unwrap_or_else(|_| "/usr/lib/softhsm/libsofthsm2.so".to_string());
                        sign_with_hsm(label, pin, &module, &h)?
                    }
                    #[cfg(not(feature = "hsm"))]
                    {
                        anyhow::bail!("HSM signing not implemented in this build; compile with --features hsm")
                    }
                } else {
                    // assume file
                    let mut key_file = File::open(kref)?;
                    let mut pkcs8 = Vec::new();
                    key_file.read_to_end(&mut pkcs8)?;
                    sign_with_keyfile(&pkcs8, &h)?
                }
            } else {
                // no keyref -> dev key
                let rng = SystemRandom::new();
                let pkcs8 = Ed25519KeyPair::generate_pkcs8(&rng).context("generate pkcs8 dev")?;
                sign_with_keyfile(pkcs8.as_ref(), &h)?
            };

            let sig_b64 = general_purpose::STANDARD.encode(&sig);
            if input.extension().and_then(|e| e.to_str()) == Some("aln") {
                // Write or append to sidecar JSON signature
                let hex_hash = hex::encode(&h);
                let sig_entry = serde_json::json!({
                    "profile": profile,
                    "signer": "dev-signer",
                    "hash": hex_hash,
                    "signature": sig_b64,
                    "timestamp": std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs()
                });
                // output file is either provided or input + .sig.json
                let out_file = if let Some(output) = output { output } else { input.with_extension("sig.json") };
                // if exists, merge into signatures array
                if out_file.exists() {
                    let mut f = File::open(&out_file)?; let mut txt = String::new(); f.read_to_string(&mut txt)?;
                    let mut sj: serde_json::Value = serde_json::from_str(&txt)?;
                    if !sj.is_object() { sj = serde_json::json!({"signatures": []}); }
                    let mut arr = sj.get_mut("signatures").and_then(|a| a.as_array_mut()).cloned().unwrap_or_else(|| Vec::new());
                    // ensure no duplicate profile
                    let mut replaced = false;
                    for existing in arr.iter_mut() {
                        if existing["profile"].as_str().unwrap_or("") == profile {
                            if !force { anyhow::bail!("signature for profile already exists in sidecar, use --force to overwrite"); }
                            *existing = sig_entry.clone(); replaced = true; break;
                        }
                    }
                    if !replaced { arr.push(sig_entry); }
                    sj["signatures"] = serde_json::Value::Array(arr);
                    let mut of = File::create(out_file)?;
                    of.write_all(serde_json::to_string_pretty(&sj)?.as_bytes())?;
                } else {
                    let sj = serde_json::json!({
                        "file": input.display().to_string(),
                        "signatures": [sig_entry]
                    });
                    let mut of = File::create(out_file)?;
                    of.write_all(serde_json::to_string_pretty(&sj)?.as_bytes())?;
                }
            } else {
                let sig_b64 = general_purpose::STANDARD.encode(&sig);
                // Append signature to YAML metadata
                let mut doc: Value = serde_yaml::from_str(&s)?;
                let sig_entry_yaml = serde_yaml::from_str::<Value>(&format!("- type: {}\n  signer: {}\n  signature: {}\n", profile, "dev-signer", sig_b64))?;
                match doc {
                    Value::Mapping(ref mut m) => {
                        if let Some(existing) = m.get_mut(&Value::String("signatures".into())) {
                            // if existing sequence, append or replace
                            if let Value::Sequence(seq) = existing {
                                let mut replaced = false;
                                for item in seq.iter_mut() {
                                    if let Value::Mapping(map) = item {
                                        if map.get(&Value::String("type".into())).and_then(|v| v.as_str()) == Some(&profile) {
                                            if !force { anyhow::bail!("signature for profile already exists in bundle; use --force"); }
                                            *item = sig_entry_yaml.clone(); replaced = true; break;
                                        }
                                    }
                                }
                                if !replaced { seq.push(sig_entry_yaml); }
                                m.insert(Value::String("signatures".into()), Value::Sequence(seq.clone()));
                            } else {
                                m.insert(Value::String("signatures".into()), sig_entry_yaml);
                            }
                        } else {
                            m.insert(Value::String("signatures".into()), sig_entry_yaml);
                        }
                    }
                    _ => {
                        anyhow::bail!("bundle YAML root must be mapping");
                    }
                }
                let out_str = serde_yaml::to_string(&doc)?;
                if let Some(output) = output {
                    let mut of = File::create(output)?;
                    of.write_all(out_str.as_bytes())?;
                } else {
                    let outname = input.with_extension("signed.yaml");
                    let mut of = File::create(outname)?;
                    of.write_all(out_str.as_bytes())?;
                }
            }
            println!("Signed bundle OK");
        }
        Cmd::Verify { input, keyref, expect_profile } => {
            // Special case: .aln with sidecar .sig.json
            if input.extension().and_then(|e| e.to_str()) == Some("aln") {
                let sig_path = input.with_extension("sig.json");
                if !sig_path.exists() { anyhow::bail!("Missing signature sidecar: {}", sig_path.display()); }
                let mut sigf = File::open(&sig_path)?; let mut sig_txt = String::new(); sigf.read_to_string(&mut sig_txt)?;
                let sj: serde_json::Value = serde_json::from_str(&sig_txt)?;
                // expected_profile must match at least one signatures[].profile value
                if let Some(expected_profile_str) = expect_profile.clone() {
                    if sj.get("signatures").is_none() { anyhow::bail!("No signatures found in sidecar"); }
                    let mut found = false;
                    for sig in sj["signatures"].as_array().unwrap_or(&Vec::new()).iter() {
                        if sig["profile"].as_str().unwrap_or("") == expected_profile_str {
                            found = true; break;
                        }
                    }
                    if !found { anyhow::bail!("Expected profile {} not found in sidecar signatures", expected_profile_str); }
                }
                // compute hash of content
                let mut f = File::open(&input)?; let mut s = String::new(); f.read_to_string(&mut s)?;
                let canonical = s.replace("\r\n", "\n").trim().to_string();
                let h = compute_hash(canonical.as_bytes());
                let hex_hash = hex::encode(&h);
                // find each signature entry that matches expected_profile or check all if not specified
                let sig_entries = if let Some(e) = expect_profile.clone() {
                    sj["signatures"].as_array().unwrap_or(&Vec::new()).iter().filter(|s| s["profile"].as_str().unwrap_or("")==e).cloned().collect::<Vec<_>>()
                } else { sj["signatures"].as_array().unwrap_or(&Vec::new()).clone() };
                if sig_entries.len() == 0 { anyhow::bail!("No matching signatures for expected profile") }
                let mut verified_any = false;
                for sitem in sig_entries.iter() {
                    let sig_b64 = sitem["signature"].as_str().unwrap_or("");
                    let sig_bytes = general_purpose::STANDARD.decode(sig_b64)?;
                    let s_hash = sitem["hash"].as_str().unwrap_or("");
                    if hex_hash != s_hash { anyhow::bail!("ALN content hash mismatch for signature entry"); }
                if let Some(kref) = keyref {
                    if kref.starts_with("hsm://") {
                        #[cfg(feature = "hsm")]
                        {
                            let rest = &kref[6..];
                            let parts: Vec<&str> = rest.split(':').collect();
                            if parts.len() != 2 { anyhow::bail!("Invalid HSM keyref format. expected hsm://label:pin") }
                            let label = parts[0]; let pin = parts[1];
                            let module = std::env::var("PKCS11_MODULE").unwrap_or_else(|_| "/usr/lib/softhsm/libsofthsm2.so".to_string());
                            let pubtemp = NamedTempFile::new()?; let out_path = pubtemp.path().to_str().unwrap().to_string();
                            export_pubkey_from_hsm(label, pin, &module, &out_path)?;
                            let mut fpub = File::open(out_path)?; let mut pubbuf = Vec::new(); fpub.read_to_end(&mut pubbuf)?;
                            if verify_with_pubkey(&pubbuf, &h, &sig_bytes)? {
                                println!("ALN signature OK for {}", input.display()); verified_any = true; break;
                            } else { anyhow::bail!("ALN signature invalid") }
                        }
                        #[cfg(not(feature = "hsm"))]
                        { anyhow::bail!("HSM verification not implemented in this build; compile with --features hsm") }
                    } else { anyhow::bail!("ALN signature invalid"); }
                } else { anyhow::bail!("No keyref provided for ALN verification"); }
                if verified_any { return Ok(()) } else { anyhow::bail!("No valid signatures verified") }
            }
            let mut f = File::open(&input)?;
            let mut s = String::new();
            f.read_to_string(&mut s)?;
            let canonical = canonicalize_yaml(&s)?;
            let h = compute_hash(canonical.as_bytes());
            let doc: Value = serde_yaml::from_str(&s)?;
            // Expect signatures at `signatures` top-level
            if let Value::Mapping(m) = doc {
                if let Some(sigs) = m.get(&Value::String("signatures".into())) {
                    match sigs {
                        Value::Sequence(seq) => {
                            let mut ok = false;
                            for item in seq.iter() {
                                if let Value::Mapping(map) = item {
                                    let ty = map.get(&Value::String("type".into())).or_else(|| map.get(&Value::String("profile".into()))).and_then(|v| v.as_str()).unwrap_or("");
                                    let signature_b64 = map.get(&Value::String("signature".into())).and_then(|v| v.as_str()).unwrap_or("");
                                    let signature = general_purpose::STANDARD.decode(signature_b64)?;
                                    // verify using provided keyref or embedded public key if available
                                    if let Some(kref) = &keyref {
                                        if kref.starts_with("hsm://") {
                                            anyhow::bail!("HSM verification not implemented in CI environment")
                                        } else {
                                            let mut key_file = File::open(kref)?; let mut pubkey = Vec::new(); key_file.read_to_end(&mut pubkey)?;
                                            if verify_with_pubkey(&pubkey, &h, &signature)? {
                                                if let Some(e) = &expect_profile {
                                                    if e == ty { ok = true; break; }
                                                } else { ok = true; break; }
                                            }
                                        }
                                    } else {
                                        // no keyref -> dev check: impossible to verify
                                    }
                                }
                            }
                            if !ok { anyhow::bail!("No valid signature found for expected profile") }
                            println!("policy bundle signature OK");
                        },
                        _ => anyhow::bail!("Invalid signatures format"),
                    }
                } else { anyhow::bail!("bundle missing signatures") }
            }
        }
        Cmd::GenerateDevKeys { output } => {
            generate_dev_keys(&output)?;
            println!("Generated dev keys at {}", output.display());
        }
        Cmd::ExportJwk { pubkey, output } => {
            // Read raw public key bytes and output a JWK for Ed25519
            let mut f = File::open(&pubkey)?; let mut buf = Vec::new(); f.read_to_end(&mut buf)?;
            // base64url without padding
            let x = general_purpose::URL_SAFE_NO_PAD.encode(&buf);
            let jwk = serde_json::json!({
                "kty": "OKP",
                "crv": "Ed25519",
                "x": x
            });
            if let Some(out) = output {
                let mut of = File::create(&out)?; of.write_all(serde_json::to_string_pretty(&jwk)?.as_bytes())?;
                println!("Wrote JWK -> {}", out.display());
            } else {
                println!("{}", serde_json::to_string_pretty(&jwk)?);
            }
        }
    }
    Ok(())
}
