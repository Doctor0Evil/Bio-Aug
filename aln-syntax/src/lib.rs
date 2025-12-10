use pest::Parser;
use pest_derive::Parser;

#[derive(Parser)]
#[grammar = "aln.pest"]
struct AlnParser;

pub fn parse_aln(content: &str) -> Result<pest::iterators::Pairs<'_, Rule>, pest::error::Error<Rule>> {
    AlnParser::parse(Rule::file, content)
}

pub mod ast; // minimal AST scaffolding in ast.rs

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn parse_example() {
        let content = std::fs::read_to_string("aln-examples/AU.BioMesh.NetEnvelope.v1.aln").expect("read example");
        let result = parse_aln(&content).expect("parse example");
        assert!(result.count() >= 0);
    }
}
