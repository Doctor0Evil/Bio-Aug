// Minimal AST types for ALN; extend as needed.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AlnFile { pub decls: Vec<Declaration> }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Declaration { System(SystemDecl), Module(ModuleDecl), Policy(PolicyDecl), Other }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemDecl { pub id: String, pub body: Vec<Declaration> }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleDecl { pub id: String }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolicyDecl { pub id: String }

// To be expanded with expressions and more complex AST shapes.
