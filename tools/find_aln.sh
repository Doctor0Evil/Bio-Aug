#!/usr/bin/env bash
set -euo pipefail
if [ -x "./target/release/aln" ]; then
  echo "./target/release/aln"
elif [ -x "./aln-cli/target/release/aln" ]; then
  echo "./aln-cli/target/release/aln"
elif command -v aln >/dev/null 2>&1; then
  command -v aln
else
  >&2 echo "aln not found"
  exit 1
fi
#!/usr/bin/env bash
set -euo pipefail

# tools/find_aln.sh:
# Resolve ALN_BIN in a robust order:
#   1) ALN_BIN env (if executable)
#   2) ./target/release/aln  (workspace build)
#   3) ./aln-cli/target/release/aln (legacy)
#   4) aln in PATH (installed globally)

try_exec() {
  local p="$1"
  if [ -n "${p}" ] && [ -x "${p}" ]; then
    echo "${p}"
    exit 0
  fi
}

# 1) Explicit env override
if [ "${ALN_BIN:-}" != "" ]; then
  try_exec "${ALN_BIN}"
fi

# 2) Workspace default
try_exec "./target/release/aln"

# 3) Legacy CLI path
try_exec "./aln-cli/target/release/aln"

# 4) System PATH
if command -v aln >/dev/null 2>&1; then
  echo "$(command -v aln)"
  exit 0
fi

echo "ERROR: Unable to locate 'aln' binary (ALN_BIN, ./target/release/aln, ./aln-cli/target/release/aln, PATH)" >&2
exit 1
