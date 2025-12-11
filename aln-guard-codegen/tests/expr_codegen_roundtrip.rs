use aln_guard_codegen::expr_to_rust;
use aln_syntax::{BinOp, Expr, UnOp};

#[test]
fn generates_simple_boolean_expr() {
    let expr = Expr::Binary {
        op: BinOp::And,
        left: Box::new(Expr::Ident("ctx.link_ok".into())),
        right: Box::new(Expr::Binary {
            op: BinOp::Lt,
            left: Box::new(Expr::Ident("ctx.torque_nm".into())),
            right: Box::new(Expr::Number(50.0)),
        }),
    };
    let code = expr_to_rust(&expr);
    assert!(code.contains("ctx.link_ok"));
    assert!(code.contains("< 50"));
}

#[test]
fn supports_unary_not_and_neg() {
    let expr = Expr::Unary {
        op: UnOp::Not,
        expr: Box::new(Expr::Ident("ctx.link_ok".into())),
    };
    let code = expr_to_rust(&expr);
    assert_eq!(code, "!(ctx.link_ok)");
}
