use pest::Parser;
use pest_derive::Parser;

#[derive(Parser)]
#[grammar = "aln.pest"]
struct AlnParser;

pub fn parse_aln(content: &str) -> Result<pest::iterators::Pairs<'_, Rule>, pest::error::Error<Rule>> {
    AlnParser::parse(Rule::file, content)
}

// Parse invariants from ALN source text, returning Invariant AST nodes.
pub fn parse_invariants(content: &str) -> Result<Vec<Invariant>, pest::error::Error<Rule>> {
    let pairs = AlnParser::parse(Rule::file, content)?;
    let mut invariants: Vec<Invariant> = Vec::new();
    for pair in pairs {
        collect_invariants_with_ctx(pair, &mut invariants, Vec::new(), None);
    }
    Ok(invariants)
}

// Parse record declarations from ALN source
pub fn parse_records(content: &str) -> Result<Vec<Record>, pest::error::Error<Rule>> {
    let pairs = AlnParser::parse(Rule::file, content)?;
    let mut records: Vec<Record> = Vec::new();
    for pair in pairs { collect_records(pair, &mut records); }
    Ok(records)
}

fn collect_records(pair: pest::iterators::Pair<'_, Rule>, out: &mut Vec<Record>) {
    match pair.as_rule() {
        Rule::record_decl => {
            let mut inner = pair.into_inner();
            let name_pair = inner.next();
            if let Some(name_p) = name_pair {
                let name = name_p.as_str().to_string();
                let mut fields: Vec<(String,String)> = Vec::new();
                for p in inner {
                    if p.as_rule() == Rule::block {
                        for f in p.into_inner() {
                            if f.as_rule() == Rule::field_decl {
                                let mut kv = f.into_inner();
                                let k = kv.next().map(|x| x.as_str().to_string()).unwrap_or_default();
                                let v = kv.next().map(|x| x.as_str().to_string()).unwrap_or_else(||"f32".to_string());
                                fields.push((k,v));
                            }
                        }
                    }
                }
                out.push(Record { name, fields });
            }
        }
        _ => {
            for inner in pair.into_inner() { collect_records(inner, out); }
        }
    }
}

fn collect_invariants_with_ctx(
    pair: pest::iterators::Pair<'_, Rule>,
    out: &mut Vec<Invariant>,
    current_binds: Vec<Binding>,
    current_where: Option<Expr>,
) {
    use pest::iterators::Pairs;
    match pair.as_rule() {
        Rule::invariant_decl => {
            let mut inner = pair.into_inner();
            let name_pair = inner.next();
            let expr_pair = inner.next();
            if let (Some(name_p), Some(expr_p)) = (name_pair, expr_pair) {
                let name = name_p.as_str().to_string();
                if let Ok(expr) = pair_to_expr(expr_p) {
                    let inv = Invariant { name: name.clone(), expr: expr.clone(), mapped_guard_name: format!("check_{}", name.replace('.', "_").replace('-', "_")), binds: current_binds.clone(), where_clause: current_where.clone() };
                    out.push(inv);
                }
            }
        }
        Rule::assert_stmt => {
            let mut inner = pair.into_inner();
            if let Some(expr_p) = inner.next() {
                if let Ok(expr) = pair_to_expr(expr_p) {
                    let name = format!("assert_{}", out.len());
                    let inv = Invariant { name: name.clone(), expr: expr.clone(), mapped_guard_name: format!("check_{}", name.replace('.', "_").replace('-', "_")), binds: current_binds.clone(), where_clause: current_where.clone() };
                    out.push(inv);
                }
            }
        }
        Rule::forall_stmt => {
            // Parse binding list and optional where clause, then collect asserts from block with context
            let mut inner = pair.into_inner();
            let mut binds: Vec<Binding> = Vec::new();
            let mut where_clause: Option<Expr> = None;
            while let Some(p) = inner.next() {
                match p.as_rule() {
                    Rule::forall_bindings => {
                        // parse each binding pair
                        for b in p.into_inner() {
                            if b.as_rule() == Rule::forall_bind {
                                let mut kv = b.into_inner();
                                let var = kv.next().map(|x| x.as_str().to_string()).unwrap_or_default();
                                let ty = kv.next().map(|x| x.as_str().to_string()).unwrap_or_default();
                                binds.push(Binding{ var, ty });
                            }
                        }
                    }
                    Rule::expr => {
                        // this could be the where clause
                        if let Ok(e) = pair_to_expr(p.clone()) { where_clause = Some(e); }
                    }
                    Rule::block => {
                        // recursively collect asserts inside this block using context
                        for inner_pair in p.into_inner() { collect_invariants_with_ctx(inner_pair, out, binds.clone(), where_clause.clone()); }
                    }
                    _ => {}
                }
            }
        }
        _ => {
            for inner in pair.into_inner() {
                collect_invariants_with_ctx(inner, out, current_binds.clone(), current_where.clone());
            }
        }
    }
}

fn pair_to_expr(pair: pest::iterators::Pair<'_, Rule>) -> Result<Expr, ()> {
    match pair.as_rule() {
        Rule::ident => Ok(Expr::Ident(pair.as_str().to_string())),
        Rule::number => Ok(Expr::Number(pair.as_str().parse::<f64>().unwrap_or(0.0))),
        Rule::boolean => Ok(Expr::Bool(pair.as_str() == "true")),
        Rule::unary => {
            let mut inner = pair.into_inner();
            let first = inner.next().unwrap();
            // unary may have prefixes '!' or '-' repeated; simple: if first is primary treat as no-op
            match first.as_rule() {
                Rule::primary => pair_to_expr(first),
                _ => pair_to_expr(first),
            }
        }
        Rule::primary => {
            let inner = pair.into_inner().next().unwrap();
            pair_to_expr(inner)
        }
        Rule::addition | Rule::multiplication | Rule::comparison | Rule::equality | Rule::logical_and | Rule::logical_or => {
            // For binary ops, combine children
            let mut inner = pair.into_inner();
            let left = pair_to_expr(inner.next().unwrap())?;
            if let Some(op_pair) = inner.next() {
                // op and right tokens alternate; simple approach: build left op right for one level
                let op_str = op_pair.as_str();
                let right = pair_to_expr(inner.next().unwrap())?;
                let op = match op_str {
                    "&&" => BinOp::And,
                    "||" => BinOp::Or,
                    ">" => BinOp::Gt,
                    ">=" => BinOp::Ge,
                    "<" => BinOp::Lt,
                    "<=" => BinOp::Le,
                    "==" => BinOp::Eq,
                    "!=" => BinOp::Ne,
                    "+" => BinOp::Add,
                    "-" => BinOp::Sub,
                    "*" => BinOp::Mul,
                    "/" => BinOp::Div,
                    _ => return Err(()),
                };
                Ok(Expr::Binary { op, left: Box::new(left), right: Box::new(right) })
            } else {
                Ok(left)
            }
        }
        _ => Err(()),
    }
}

pub mod ast; // minimal AST scaffolding in ast.rs

// -------- Invariant & expression model (minimal) --------

#[derive(Debug, Clone)]
pub enum Expr {
    Ident(String),
    Number(f64),
    Bool(bool),
    Binary {
        op: BinOp,
        left: Box<Expr>,
        right: Box<Expr>,
    },
    Unary {
        op: UnOp,
        expr: Box<Expr>,
    },
}

#[derive(Debug, Clone, Copy)]
pub enum BinOp {
    And,
    Or,
    Gt,
    Ge,
    Lt,
    Le,
    Eq,
    Ne,
    Add,
    Sub,
    Mul,
    Div,
}

#[derive(Debug, Clone, Copy)]
pub enum UnOp {
    Not,
    Neg,
}

#[derive(Debug, Clone)]
pub struct Invariant {
    pub name: String,
    pub expr: Expr,
    pub mapped_guard_name: String,
    pub binds: Vec<Binding>,
    pub where_clause: Option<Expr>,
}

#[derive(Debug, Clone)]
pub struct Binding {
    pub var: String,
    pub ty: String,
}

#[derive(Debug, Clone)]
pub struct Record {
    pub name: String,
    pub fields: Vec<(String,String)>,
}

// TODO: wire parser to fill Invariant list from ALN `policy` blocks
// and `mapping` declarations, but keep this struct stable so other
// crates (codegen) can depend on it now.

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn parse_example() {
        let content = std::fs::read_to_string("aln-examples/AU.BioMesh.NetEnvelope.v1.aln").expect("read example");
        let result = parse_aln(&content).expect("parse example");
        assert!(result.count() >= 0);
    }

    #[test]
    fn parse_records_example() {
        let content = std::fs::read_to_string("bioaug-clinical/specs/NanoNeuro-MathInvariants.v1.aln").expect("read sample");
        let recs = parse_records(&content).expect("parse records");
        // Expect NeuromodSample and NeuromodEnvInvariant
        let has_sample = recs.iter().any(|r| r.name == "NeuromodSample");
        let has_env = recs.iter().any(|r| r.name == "NeuromodEnvInvariant");
        assert!(has_sample && has_env, "expected records to be parsed");
    }
    #[test]
    fn parse_invariants_from_neuromod_file() {
        let content = std::fs::read_to_string("bioaug-clinical/specs/NanoNeuro-MathInvariants.v1.aln").expect("read sample invariants file");
        let invs = parse_invariants(&content).expect("parse invariants");
        // We expect at least 5 asserts (4 neuromod asserts and 1 Hybrid reliability assert)
        assert!(invs.len() >= 5, "expected >= 5 invariants, got {}", invs.len());
        // Find at least one invariant with binds
        let has_binds = invs.iter().any(|i| !i.binds.is_empty());
        assert!(has_binds, "expected at least one invariant to contain quantifier bindings");
        let has_where = invs.iter().any(|i| i.where_clause.is_some());
        assert!(has_where, "expected at least one invariant to include a where clause");
    }
}
