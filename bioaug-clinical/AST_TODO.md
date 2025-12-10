# ALN AST & Semantic Engine (TODO)

- Implement a full ALN PEG grammar and corresponding AST builder using `pest` or `nom`:
  - Create a comprehensive grammar `aln.pest` covering declarations, policies, expressions, guards, conditions, traceability blocks, and comments.
  - Implement a robust AST with nodes for systems, policies, guards, traceability, types, and conditions.

- Semantic checks to add:
  - Name resolution and imports (detect duplicates, dangling references).
  - Guard type checking including numeric types, range checking, and unit inference.
  - Dead code detection (unreachable policies or guards).
  - Policy composition and priority analysis to detect conflicting or mis-ordered policies.

- Tests & validation:
  - Round-trip tests: parse -> AST -> render -> parse should be idempotent.
  - Semantic test suite: positive & negative cases for property checks.

- Integration & CI:
  - Use AST to drive `aln-check::semantic_check` in CI instead of heuristic string scanning.
  - Export detailed semantic reports in JSON for auditors and product teams.
