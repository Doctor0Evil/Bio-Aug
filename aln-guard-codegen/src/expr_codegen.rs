use aln_syntax::{BinOp, Expr, Invariant, UnOp};

pub fn expr_to_rust(expr: &Expr) -> String {
    match expr {
        Expr::Ident(name) => {
            // If identifier already looks like ctx.* or contains '.', keep as-is, otherwise qualify with ctx.
            let n = name.as_str();
            let qualified = match n {
                "torque" | "torque_nm" => "ctx.torque_nm".to_string(),
                "current" | "current_amp" => "ctx.current_amp".to_string(),
                "pressure" | "pressure_kpa" => "ctx.pressure_kpa".to_string(),
                "link_ok" => "ctx.link_ok".to_string(),
                _ => {
                    if n.starts_with("ctx.") || n.contains('.') { n.to_string() } else { format!("ctx.{}", n) }
                }
            };
            qualified
        }
        Expr::Number(n) => format!("{}", n),
        Expr::Bool(b) => format!("{}", b),
        Expr::Unary { op, expr } => {
            let inner = expr_to_rust(expr);
            match op {
                UnOp::Not => format!("!({})", inner),
                UnOp::Neg => format!("-({})", inner),
            }
        }
        Expr::Binary { op, left, right } => {
            let l = expr_to_rust(left);
            let r = expr_to_rust(right);
            let op_str = match op {
                BinOp::And => "&&",
                BinOp::Or => "||",
                BinOp::Gt => ">",
                BinOp::Ge => ">=",
                BinOp::Lt => "<",
                BinOp::Le => "<=",
                BinOp::Eq => "==",
                BinOp::Ne => "!=",
                BinOp::Add => "+",
                BinOp::Sub => "-",
                BinOp::Mul => "*",
                BinOp::Div => "/",
            };
            format!("({} {} {})", l, op_str, r)
        }
    }
}

/// Generate a typed guard function from an Invariant.
/// Signature pattern:
///   pub fn <mapped_guard_name>(ctx: &GuardContext) -> bool { <expr> }
pub fn invariant_to_fn(inv: &Invariant) -> String {
    let body = expr_to_rust(&inv.expr);
    let fn_name = &inv.mapped_guard_name;
    // collect idents to generate typed args
    let mut idents = std::collections::HashSet::new();
    collect_idents(&inv.expr, &mut idents);
    let mut params: Vec<String> = Vec::new();
    for id in idents.iter() {
        let param = match id.as_str() {
            "torque" | "torque_nm" => "torque_nm: f64".to_string(),
            "current" | "current_amp" => "current_amp: f64".to_string(),
            "pressure" | "pressure_kpa" => "pressure_kpa: f64".to_string(),
            "link_ok" => "link_ok: bool".to_string(),
            _ => format!("{}: f64", id),
        };
        params.push(param);
    }
    // stable order
    params.sort();
    let params_str = params.join(", ");
    // If there are quantifier binds, emit loops with ctx collections and the assertion inside.
    if !inv.binds.is_empty() {
        // Create a typed single-item function with bind params
        let mut single_params: Vec<String> = Vec::new();
        let mut single_args: Vec<String> = Vec::new();
        for bind in &inv.binds {
            let ty = match bind.ty.as_str() {
                "NeuromodSample" => "&NeuromodSample".to_string(),
                "NeuromodEnvInvariant" => "&NeuromodEnvInvariant".to_string(),
                other => format!("&{}", other),
            };
            single_params.push(format!("{}: {}", bind.var, ty));
            single_args.push(bind.var.clone());
        }
        let single_fn_name = format!("{}_single", fn_name);
        let single_sig = format!("pub fn {}({}) -> bool {{\n    {}\n}}\n", single_fn_name, single_params.join(", "), body);

        // Start the wrapper ctx function signature with ctx only and call single fn for each item
        let mut body_out = String::new();
        // Build nested loops in wrapper
        for bind in &inv.binds {
            let field_name: String = match bind.ty.as_str() {
                "NeuromodSample" => "neuromod_samples".to_string(),
                "NeuromodEnvInvariant" => "neuromod_envs".to_string(),
                other => format!("{}s", other.to_lowercase()),
            };
            body_out.push_str(&format!("for {} in &ctx.{} {{\n    ", bind.var, field_name));
        }
        // Where clause handling: if present, continue when false
        if let Some(where_expr) = &inv.where_clause {
            let where_rust = expr_to_rust(where_expr);
            body_out.push_str(&format!("if !({}) {{ continue; }}\n    ", where_rust));
        }
        // Call typed single fn, return false if false
        body_out.push_str(&format!("if !({}({})) {{ return false; }}\n", single_fn_name, single_args.join(", ")));
        // Close the loops
        for _ in 0..inv.binds.len() { body_out.push_str("}\n") }
        body_out.push_str("\n    true\n");
        let wrapper_sig = format!("pub fn {fn_name}(ctx: &GuardContext) -> bool {{\n    {body}\n}}\n", fn_name = fn_name, body = body_out);
        return format!("{}\n{}", single_sig, wrapper_sig);
    }
    // No quantifiers - use params approach
    format!(
        "pub fn {fn_name}({params}) -> bool {{\n    {body}\n}}\n",
        fn_name = fn_name,
        params = params_str,
        body = body
    )
}

fn collect_idents(expr: &Expr, set: &mut std::collections::HashSet<String>) {
    match expr {
        Expr::Ident(name) => {
            // strip ctx. if present
            let n = if name.starts_with("ctx.") { name.trim_start_matches("ctx.").to_string() } else { name.clone() };
            set.insert(n);
        }
        Expr::Binary { left, right, .. } => { collect_idents(left, set); collect_idents(right, set); }
        Expr::Unary { expr, .. } => { collect_idents(expr, set); }
        _ => {}
    }
}

/// Generate a full module from multiple invariants.
pub fn invariants_to_module(module_name: &str, invariants: &[Invariant], records: &[aln_syntax::Record]) -> String {
    let mut out = String::new();
    out.push_str(&format!("pub mod {} {{\n", module_name));
    // Emit record struct definitions using record_codegen
    use crate::record_codegen::records_to_rust;
    out.push_str(&records_to_rust(records));
    // Generate GuardContext that contains Vec<T> fields for record types that appear in binds
    let mut used_types: std::collections::HashSet<String> = std::collections::HashSet::new();
    for inv in invariants { for b in &inv.binds { used_types.insert(b.ty.clone()); } }
    out.push_str("    pub struct GuardContext {\n");
    for ty in used_types.iter() {
        out.push_str(&format!("        pub {}s: Vec<{}>,\n", ty.to_lowercase(), ty));
    }
    // Add simple telemetry fields commonly referenced
    out.push_str("        pub torque_nm: f64,\n");
    out.push_str("        pub current_amp: f64,\n");
    out.push_str("        pub pressure_kpa: f64,\n");
    out.push_str("        pub link_ok: bool,\n");
    out.push_str("    }\n\n");
    out.push_str("\n");
    for inv in invariants {
        out.push_str(&invariant_to_fn(inv));
        out.push_str("\n");
    }
    out.push_str("}\n");
    out
}
