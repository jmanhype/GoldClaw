# SVE → Automaton Migration Plan

## Overview
Migrate from rigid Python SVE system to flexible Automaton runtime with Conway wallet integration.

## SVE Operations to Migrate

### Infrastructure
- `infra.launch` - Spin up Conway sandboxes
- `infra.register_domain` - Register domains via Conway

### Growth (GEO)
- `growth.geo_audit` - Audit domain, DNS, wallet status
- `growth.geo_inject` - Draft GEO content strategies
- `growth.geo_apply` - Apply GEO implementations

### Marketing
- `marketing.layers_sync` - Sync campaigns to Layers API

### Sales
- `sales.deal_closing_loop` - Pipeline sync, proposals, contracts, closing
- `sales.pipeline_sync` - CRM sync, deal tracking
- `sales.followup_send` - Follow-up emails
- `sales.proposal_send` - Send proposals (batch)
- `sales.contract_send` - Send contracts (batch)
- `sales.contract_track` - Track contract status
- `sales.close_deal` - Auto-close deals
- `sales.outbound_email_send` - Outbound emails
- `sales.meeting_booking` - Meeting coordination
- `sales.crm_sync` - CRM updates

### Strategy
- `strategy.hypothesis_generate` - Generate growth hypotheses
- `strategy.experiment_launch` - Launch experiments
- `strategy.experiment_evaluate` - Evaluate experiments
- `strategy.experiment_decide` - Decide on next actions
- `strategy.product_repo_loop` - Weekly repo analysis
- `strategy.product_execution_loop` - GitHub dispatch, deploy, telemetry

### Operations
- `ops.generate_changelog` - Generate changelogs

## Migration Strategy

### Phase 1: Automaton Setup
1. ✓ Clone Automaton repo
2. ✓ Build with `pnpm install && pnpm build`
3. Run setup wizard (`node dist/index.js --run`)
4. Configure genesis prompt
5. Test basic operations

### Phase 2: Core Skills Development
Write SVE operations as Automaton skills:
- Conway wallet operations (already in tools)
- Sales automation skills
- Growth operations skills
- Strategy loop skills

### Phase 3: Genesis Prompt Design
Craft genesis prompt that:
- Defines agent identity (vaos.sh sovereign operator)
- Sets autonomous loops (sales, growth, strategy)
- Implements survival pressure logic
- Specifies safety constraints

### Phase 4: SVE Decommission
1. Disable SVE heartbeat/tick services
2. Archive ledger data
3. Stop Discord/Telegram command routing to SVE
4. Route commands through me → Automaton state

### Phase 5: Testing & Iteration
1. Run in parallel initially
2. Compare outputs
3. Gradual migration of operations
4. Final decommission

## Configuration Mapping

| SVE Config | Automaton Config |
|------------|------------------|
| `daily_budget_usdc` | Treasury policy |
| `per_action_cap_usdc` | Spend tracking |
| `domain_daily_cap_usdc` | Per-domain limits |
| `autopilot_enabled` | Genesis prompt loops |
| `autopilot_*_interval_min` | Heartbeat schedule |
| `conway_network` | `eip155:8453` (Base) |

## Data Migration

### SVE Ledger → Automaton State DB
- Keep SVE ledger for historical reference
- Start fresh in Automaton state
- Optional: export summary to memory

### Wallet
- Continue using existing Conway wallet
- Automaton will generate new wallet on setup
- Fund old wallet into new wallet

## Timeline Estimate
- Phase 1: 1-2 hours
- Phase 2: 1-2 days
- Phase 3: 2-4 hours
- Phase 4: 30 minutes
- Phase 5: 1-2 days

Total: 3-5 days
