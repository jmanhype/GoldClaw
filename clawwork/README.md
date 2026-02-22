# ClawWork Mode Workspace

This folder is the local contract for `#autonomous-revenue` in ClawWork founder mode.

## Files

- `ledger_schema.sql` - SQLite schema for virtual P&L, actions, and evidence.
- `ledger.sqlite` - Optional local ledger database.

## One-time initialization

```bash
mkdir -p /Users/speed/.openclaw/workspace/clawwork
sqlite3 /Users/speed/.openclaw/workspace/clawwork/ledger.sqlite < /Users/speed/.openclaw/workspace/clawwork/ledger_schema.sql
```

## Intent

- Keep economics explicit and auditable.
- Distinguish simulated benchmarking from executed business actions.
- Store evidence paths for every claimed outcome.
