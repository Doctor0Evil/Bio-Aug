use anyhow::Result;

pub fn generate_rust_stub(_aln: &str, _out_dir: &str) -> Result<()> {
    // Placeholder: read ALN, generate a minimal Rust stub representing one struct.
    // TODO: Implement full codegen with AST-based generation.
    println!("aln-codegen: generate_rust_stub (placeholder)");
    Ok(())
}

pub fn generate_wasm(_aln: &str, out_file: &str) -> Result<()> {
    // Placeholder: write a tiny WASM module (empty) to the out file
    use std::fs::File;
    use std::io::Write;
    let mut f = File::create(out_file)?;
    // Minimal WASM header (empty module) - just write placeholder text
    f.write_all(b"\0asm\x01\0\0\0 (placeholder WASM)")?;
    println!("aln-codegen: generated placeholder wasm -> {}", out_file);
    Ok(())
}
