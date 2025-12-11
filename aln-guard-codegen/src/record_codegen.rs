use aln_syntax::Record;

fn aln_type_to_rust(ty: &str) -> String {
    match ty {
        "string" => "String".to_string(),
        "f32" | "f64" => "f64".to_string(),
        "i32" => "i32".to_string(),
        "u32" => "u32".to_string(),
        "bool" => "bool".to_string(),
        _ => "String".to_string(),
    }
}

pub fn record_to_rust(rec: &Record) -> String {
    let mut out = String::new();
    out.push_str(&format!("    pub struct {} {{\n", rec.name));
    for (field, ty) in &rec.fields {
        let rtype = aln_type_to_rust(ty);
        out.push_str(&format!("        pub {}: {},\n", field, rtype));
    }
    out.push_str("    }\n\n");
    out
}

pub fn records_to_rust(records: &[Record]) -> String {
    let mut out = String::new();
    for rec in records {
        out.push_str(&record_to_rust(rec));
    }
    out
}
