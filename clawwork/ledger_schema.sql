PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS budget_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  start_balance_usd REAL NOT NULL DEFAULT 10.0,
  current_balance_usd REAL NOT NULL DEFAULT 10.0,
  updated_ts TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (datetime('now')),
  domain TEXT NOT NULL,
  area TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('SIMULATED', 'EXECUTED')),
  objective TEXT NOT NULL,
  execution TEXT NOT NULL,
  artifact TEXT NOT NULL,
  result TEXT NOT NULL,
  est_cost_usd REAL NOT NULL DEFAULT 0.0,
  actual_cost_usd REAL NOT NULL DEFAULT 0.0
);

CREATE TABLE IF NOT EXISTS opportunities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (datetime('now')),
  source TEXT NOT NULL,
  title TEXT NOT NULL,
  stage TEXT NOT NULL,
  value_usd REAL NOT NULL DEFAULT 0.0,
  evidence TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS metrics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (datetime('now')),
  metric TEXT NOT NULL,
  value REAL NOT NULL,
  note TEXT
);

CREATE TABLE IF NOT EXISTS clawwork_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL DEFAULT (datetime('now')),
  instruction TEXT NOT NULL,
  gdpval_occupation TEXT NOT NULL,
  bls_occupation TEXT NOT NULL,
  hourly_wage REAL NOT NULL,
  confidence TEXT NOT NULL,
  estimated_hours REAL NOT NULL,
  max_payment_usd REAL NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('SIMULATED', 'EXECUTED')),
  artifact_target TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned'
);

INSERT INTO budget_state (id, start_balance_usd, current_balance_usd)
SELECT 1, 10.0, 10.0
WHERE NOT EXISTS (SELECT 1 FROM budget_state WHERE id = 1);
