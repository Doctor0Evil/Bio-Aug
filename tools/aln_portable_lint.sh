#!/usr/bin/env bash
set -e
# Portable ALN linter wrapper with auto-build support
# - No external package manager assumptions
# - Delegates to existing ./aln-cli binary or repo-local aln binary if present
# - If `--auto-build` is passed and `aln` is not found, attempts to build aln-cli
# - Fails fast on syntax/semantic errors for all *.aln under specs/ and policies/

ROOT='bioaug-clinical'
CLI_CANDIDATES=(
  './aln-cli/target/release/aln'
  './target/release/aln'
  './aln'
  'aln'
)

auto_build=false
if [ "$1" = "--auto-build" ]; then
  auto_build=true
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Try tools/find_aln.sh first (cross-platform, not requiring an executable bit)
ALN_BIN=''
if [ -f "$SCRIPT_DIR/../../tools/find_aln.sh" ]; then
  ALN_BIN="${ALN_BIN:-$(sh "$SCRIPT_DIR/../../tools/find_aln.sh" 2>/dev/null || true)}"
fi
ALN_BIN="${ALN_BIN:-}" 
for c in "${CLI_CANDIDATES[@]}"; do
  # If the candidate is in PATH, command -v finds it; otherwise check for executable file
  if command -v "$c" >/dev/null 2>&1; then
    ALN_BIN="$c"
    break
  fi
  if [ -x "$c" ]; then
    ALN_BIN="$c"
    break
  fi
done

if [ -z "$ALN_BIN" ] && $auto_build; then
  if [ -d "aln-cli" ]; then
    echo "Auto-building aln-cli..."
    (cd aln-cli && cargo build --release)
    if [ -x "./aln-cli/target/release/aln" ]; then
      ALN_BIN="./aln-cli/target/release/aln"
    fi
  fi
fi

if [ "${AUTO_BUILD:-0}" = "1" ] || printf '%s\n' "$@" | grep -q -- '--auto-build'; then
  echo "[aln-lint] auto-build enabled via AUTO_BUILD or --auto-build; building workspace aln-cli..." >&2
  cargo build --release -p aln-cli
  if [ -x "./target/release/aln" ]; then
    ALN_BIN='./target/release/aln'
  fi
fi

if [ -z "$ALN_BIN" ]; then
  echo "ERROR: No ALN binary found (tried: ${CLI_CANDIDATES[*]}), and auto-build not successful." >&2
  exit 1
fi

echo "Using ALN binary: $ALN_BIN"

find "$ROOT/specs" "$ROOT/policies" -name '*.aln' -print0 2>/dev/null \
  | xargs -0 -n1 -I{} "$ALN_BIN" lint {} || exit 1

if [ -f "$ROOT/aln-workspace.toml" ] || [ -f "$ROOT/aln_workspace.toml" ]; then
  "$ALN_BIN" validate --workspace "$ROOT" --profile bioaug-clinical || true
fi
#!/usr/bin/env bash
set -e
# Portable ALN linter wrapper:
# - No external package manager assumptions
# - Delegates to existing ./aln-cli binary or repo-local aln binary if present
# - Fails fast on syntax/semantic errors for all *.aln under specs/ and policies/

ROOT='bioaug-clinical'
CLI_CANDIDATES=(
  './aln-cli/target/release/aln'
  './aln'
  'aln'
)

ALN_BIN=''
for c in "${CLI_CANDIDATES[@]}"; do
  # If the candidate is in PATH, command -v finds it; otherwise check for executable file
  if command -v "$c" >/dev/null 2>&1; then
    ALN_BIN="$c"
    break
  fi
  if [ -x "$c" ]; then
    ALN_BIN="$c"
    break
  fi
done

if [ -z "$ALN_BIN" ]; then
  echo "ERROR: No portable ALN binary found (expected one of: ${CLI_CANDIDATES[*]})." >&2
  exit 1
fi

# 1) Syntax/semantic lint for specs and policies.
if [ -d "$ROOT/specs" ]; then
  find "$ROOT/specs" -name '*.aln' -print0 2>/dev/null | xargs -0 -n1 -I{} "$ALN_BIN" lint {} || exit 1
fi
if [ -d "$ROOT/policies" ]; then
  find "$ROOT/policies" -name '*.aln' -print0 2>/dev/null | xargs -0 -n1 -I{} "$ALN_BIN" lint {} || exit 1
fi

# 2) Optional workspace-level validate if profile exists.
if [ -f "$ROOT/aln-workspace.toml" ] || [ -f "$ROOT/aln_workspace.toml" ]; then
  "$ALN_BIN" validate --workspace "$ROOT" --profile bioaug-clinical || true
fi
