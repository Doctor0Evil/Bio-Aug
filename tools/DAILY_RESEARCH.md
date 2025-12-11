# Daily Research Scripts

This folder contains scripts to help you generate daily ALN profiles and typed Rust guard modules.

Files:
- `daily_research_cycle.sh` — generate a single daily biomech/BCI ALN profile and guard crate.
- `daily_cybernetic_cycle.sh` — generate an ALN profile for rotating cybernetic domains, guards and Prometheus metrics.
- `daily_adjacent_cycle.sh` — Adjacent-domain generator (implantable, organic, soft robotics, cyber-immune).
- `daily_nanoswarm_cycle.sh` — Nanoswarm write profile generator + crate scaffolding and codegen integration.

Usage (on a dev machine / CI runner with dependencies installed):

1. Ensure `aln-cli` or `./tools/find_aln.sh` returns a valid binary path.
2. Ensure dependencies: `jq`, `sha256sum` (or equivalent), and `git` (optional).
3. Run the script you want, e.g.:

```bash
./tools/daily_research_cycle.sh
# or
./tools/daily_cybernetic_cycle.sh
# or
./tools/daily_adjacent_cycle.sh
# or
./tools/daily_nanoswarm_cycle.sh
```

4. Each script creates daily ALN profile(s), a generated Rust guards module in `generated/` and a small crate publishing stub in the workspace (e.g. `daily-guards-YYYYMMDD/`).
5. The script writes out Prometheus example templates under `prometheus/` and logs actions to `research-logs/`.

Notes:
- These scripts are templates for CI and developer machines; they assume a POSIX environment with standard utilities.
- Use feature `--features clinical-le` where appropriate if you intend to include governance- or HSM-protected artifacts.
- Update or extend `aln` templates, invariants, and metrics as your domain research progresses.
