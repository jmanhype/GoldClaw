# SVE → Automaton Migration Status

## ✅ Phase 1: Automaton Setup — COMPLETE

### Configuration Summary

**Wallet:**
- Address: `0xD1Fbc3F18255df94DEB98644653583dD4239D2A1`
- USDC Balance: **18.71 USDC** (funded! ✅)
- Network: Base (eip155:8453)

**Agent Identity:**
- Name: vaos-automaton
- State: sleeping (ready to run)
- Model: gpt-5.2
- Version: 0.1.0

**Heartbeat Schedule (6 active):**
- Sales loop: every 3 hours
- Growth loop: every 6 hours
- Marketing loop: every 6 hours
- Strategy loop: every 12 hours
- Health check: every 30 minutes
- Credit monitor: every 15 minutes

**Treasury Policy:**
- Max single transfer: $50.00
- Max daily transfer: $250.00
- Minimum reserve: $10.00
- Max inference daily: $500.00
- Require confirmation above: $10.00

**Model Strategy:**
- Normal: gpt-5.2 (4096 tokens)
- Low compute: gpt-4.5 (2048 tokens)
- Critical: gpt-4.0 (1024 tokens)

### Genesis Prompt Loaded

The automaton has a comprehensive genesis prompt that defines:
- Sales automation operations
- Growth GEO operations
- Strategy experiment loop
- Marketing sync tasks
- Survival rules
- Safety constraints
- Operating modes (GROWTH/SURVIVAL)

## 🔄 Phase 2: Skills Development — IN PROGRESS (10/17)

### Skills Built (10/17)

**Sales Automation (6/6):**
- ✅ `sales_pipeline_sync` - Sync pipeline, track status transitions
- ✅ `sales_followup_send` - Send follow-ups to active opportunities
- ✅ `sales_close_deal` - Check Stripe sessions, close deals
- ✅ `sales_proposal_send` - Send proposals to qualified leads
- ✅ `sales_contract_send` - Send contracts to deal-ready prospects
- ✅ `sales_contract_track` - Monitor contract status

**Growth (3/3):**
- ✅ `growth_geo_audit` - Audit domain, DNS, wallet health
- ✅ `growth_geo_inject` - Draft GEO content strategies
- ✅ `growth_geo_apply` - Apply GEO implementations

**Marketing (1/1):**
- ✅ `marketing_layers_sync` - Sync campaigns to Layers API

**Strategy (1/5):**
- ✅ `strategy_hypothesis_generate` - Generate growth hypotheses
- ⏳ `strategy_experiment_launch` - Launch experiments
- ⏳ `strategy_experiment_evaluate` - Evaluate experiments
- ⏳ `strategy_experiment_decide` - Decide on next actions
- ⏳ `strategy_product_repo_loop` - Weekly repo analysis

**Other (0/5):**
- ⏳ `sales_outbound_email_send` - Outbound emails
- ⏳ `sales_meeting_booking` - Meeting coordination
- ⏳ `sales_crm_sync` - CRM updates
- ⏳ `ops_generate_changelog` - Generate changelogs

### Skills Registry

Updated `~/.automaton/skills/index.ts` with:
- All 10 built skills exported
- Skills registry mapping names to implementations
- Heartbeat schedule for each skill (cron expressions)

### Completion Progress

```
Skills Built:     10/17 (59%)
Sales:            6/6 ✅ COMPLETE
Growth:           3/3 ✅ COMPLETE
Marketing:        1/1 ✅ COMPLETE
Strategy:         1/5 (20%)
Other:            0/5 (0%)
```

### SVE Operations Mapped to Automaton

| SVE Intent | Automaton Approach |
|------------|-------------------|
| `sales.pipeline_sync` | Skill: `sales_pipeline_sync` |
| `sales.followup_send` | Skill: `sales_followup_send` |
| `sales.proposal_send` | Skill: `sales_proposal_send` |
| `sales.contract_send` | Skill: `sales_contract_send` |
| `sales.contract_track` | Skill: `sales_contract_track` |
| `sales.close_deal` | Skill: `sales_close_deal` |
| `sales.outbound_email_send` | Skill: `sales_outbound_email` |
| `sales.meeting_booking` | Skill: `sales_meeting_book` |
| `sales.crm_sync` | Tool: built-in `exec` + webhook |
| `growth.geo_audit` | Skill: `growth_geo_audit` |
| `growth.geo_inject` | Skill: `growth_geo_inject` |
| `growth.geo_apply` | Skill: `growth_geo_apply` |
| `marketing.layers_sync` | Skill: `marketing_layers_sync` |
| `strategy.hypothesis_generate` | Skill: `strategy_hypothesis` |
| `strategy.experiment_launch` | Skill: `strategy_experiment_launch` |
| `strategy.experiment_evaluate` | Skill: `strategy_experiment_eval` |
| `strategy.experiment_decide` | Skill: `strategy_experiment_decide` |
| `strategy.product_repo_loop` | Skill: `strategy_repo_loop` |
| `strategy.product_execution_loop` | Skill: `strategy_execution_loop` |
| `ops.generate_changelog` | Skill: `ops_changelog` |
| `infra.launch` | Tool: built-in via Conway client |
| `infra.register_domain` | Tool: built-in via Conway client |

## 📋 Phase 3: Skills Integration — IN PROGRESS

### Skills in SKILL.md Format (4/10)

Converted 4 critical skills to Automaton's SKILL.md format:

**Sales (3):**
- ✅ `sales_pipeline_sync` - Pipeline sync with SVE ledger & webhook dispatch
- ✅ `sales_followup_send` - Follow-up messaging with idempotency
- ✅ `sales_close_deal` - Stripe session checking & deal closing

**Growth (1):**
- ✅ `growth_geo_audit` - Conway wallet, domain, DNS audits

**Marketing (1):**
- ✅ `marketing_layers_sync` - Layers API campaign sync

**Strategy (1):**
- ✅ `strategy_hypothesis_generate` - Growth hypothesis generation

### Integration Progress

**✅ Completed:**
1. State DB Connection - Skills use SVE SQLite ledger directly
2. Conway Client - Skills use `npx conway-terminal` commands
3. Stripe Integration - `sales_close_deal` checks Stripe sessions
4. Webhook Dispatch - All skills include webhook fallback logic
5. Idempotency - All skills use hour/day-based idempotency keys

**⏳ Remaining:**
6. Create test harness for skill execution
7. Install skills in Automaton via `install_skill` tool
8. Test skill execution locally
9. Verify outputs match SVE behavior

### Data Flow

```
SVE SQLite Ledger (~/.openclaw/workspace/sve/ledger.sqlite)
    ↓
SKILL.md Skills (~/.automaton/skills/*/)
    ↓
Conway Terminal (npx conway-terminal)
    ↓
Stripe API (curl to api.stripe.com)
    ↓
Webhook Rails (existing SVE infrastructure)
    ↓
External Systems (CRM, email, etc.)
```

### Testing Commands

**After starting Automaton, install skills:**
```bash
# Use install_skill built-in tool
install_skill path="~/.automaton/skills/sales_pipeline_sync/SKILL.md"
install_skill path="~/.automaton/skills/growth_geo_audit/SKILL.md"
```

**Test skills directly (bypass Automaton):**
```bash
# Manual execution test
sqlite3 ~/.openclaw/workspace/sve/ledger.sqlite "SELECT COUNT(*) FROM opportunities"
npx conway-terminal wallet_info
```

### Phase 3-5: Remaining Work

**Phase 4: SVE Decommission (After Testing)**
- Stop SVE heartbeat/tick services
- Archive ledger data
- Route Discord commands to Automaton
- Final validation

**Phase 5: Parallel Testing & Final Migration**
- Run both SVE and Automaton simultaneously
- Compare outputs and decisions
- Gradually shift operations to Automaton
- Decommission SVE when stable

## 🎯 Next Steps

1. Build first skill: `sales_pipeline_sync` (highest priority for revenue)
2. Test skill execution locally
3. Integrate with heartbeat schedule
4. Validate outputs match SVE behavior
5. Repeat for remaining skills

## 🔑 Key Advantages Over SVE

- **Self-modification**: Can optimize itself over time
- **Flexible operations**: Add skills, not edit code
- **Survival pressure**: Must create value or die
- **Conway integration**: Native wallet and compute
- **Official support**: Actively maintained
- **Replication**: Can spawn child agents
- **Extensible**: Skill system for new capabilities
