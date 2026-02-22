# ClawWork Routing Contract (OpenClaw Channel)

## Command

- `/clawwork <instruction>`

## Classification dataset

- `/Users/speed/.openclaw/workspace/clawwork/occupation_to_wage_mapping.json`

## Value formula

- `max_payment_usd = estimated_hours * hourly_wage`

## Ledger DB

- `/Users/speed/.openclaw/workspace/clawwork/ledger.sqlite`

## Task insert template

```sql
INSERT INTO clawwork_tasks (
  instruction,
  gdpval_occupation,
  bls_occupation,
  hourly_wage,
  confidence,
  estimated_hours,
  max_payment_usd,
  mode,
  artifact_target,
  status
) VALUES (
  :instruction,
  :gdpval_occupation,
  :bls_occupation,
  :hourly_wage,
  :confidence,
  :estimated_hours,
  :max_payment_usd,
  :mode,
  :artifact_target,
  :status
);
```

