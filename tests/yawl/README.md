# YAWL Test Case: Wyoming LLC Reinstatement

**Test ID:** WY-LLC-REINSTATE-001
**Workflow ID:** wy-reinstatement-flow
**Created:** 2026-02-21

## Overview

This test case simulates the Wyoming LLC reinstatement process using YAWL (Yet Another Workflow Language) with GODSPEED-ggen integration. It models the end-to-end workflow of reinstating a lapsed LLC, including decision points for agent-filing vs self-filing, payment processing, validation, and receipt generation.

## Files

| File | Description |
|------|-------------|
| `llc-reinstatement-test.yaml` | Test case specification with scenarios, data, and assertions |
| `llc-reinstatement-workflow.xml` | YAWL workflow definition (executable) |
| `skills-discovery-reinstatement.rq` | SPARQL queries for discovering relevant skills |
| `run-reinstatement-test.sh` | Test execution script |
| `README.md` | This file |

## Workflow Diagram

```
[Start]
   ↓
[Receive Lapse Notice] (Ψ - Perception)
   ↓
[Assess Options] (Decision Point)
   ↓
   ├─→ [Request Agent Services] → [Process Payment ($417)] → [Agent Filing]
   │                                                              ↓
   └─→ [Navigate SOS Portal] → [Self File] → [Process Payment ($204)] ↓
                                                                   ↓
                                                        [Validate] (Q - Observe)
                                                                   ↓
                                                        [Generate Receipt] (Λ - Build)
                                                                   ↓
                                                        [Update Registry] (Ω - Optimize)
                                                                   ↓
                                                        [End]
```

## GODSPEED Phase Mapping

| Phase | Name | Task |
|-------|------|------|
| Ψ | Perception | Receive Lapse Notice |
| Λ | Build | Assess Reinstatement Options |
| H | Deploy | Agent/Self Filing Submission |
| Q | Observe | Validate Reinstatement |
| Ω | Optimize | Generate Receipt + Update Registry |

## Test Scenarios

### SCENARIO-001: Agent-filing with privacy protection
- **Path:** hire_agent
- **Cost:** $417 (agent fees included)
- **Privacy:** Owner name kept off public record
- **Timeline:** 15-20 business days

### SCENARIO-002: Self-filing for cost savings
- **Path:** self_file
- **Cost:** $204 (state fee only)
- **Privacy:** Owner signature on permanent public record
- **Timeline:** Varies (DIY)

### SCENARIO-003: Reinstatement failure retry
- **Path:** hire_agent
- **Validation:** Simulates first submission failure
- **Retry:** Automatic retry with exponential backoff
- **Max retries:** 3 attempts

## Prerequisites

1. **YAWL Engine**: Running at `http://localhost:8080/yawl`
2. **Observatory**: Running at `http://localhost:9090/observatory` (for SPARQL queries)
3. **Tools**:
   - `curl` (for API calls)
   - `jq` (for JSON processing)
   - `yq` (for YAML processing)

## Running the Test

### Quick Start

```bash
# Set environment variables (optional, defaults shown)
export YAWL_ENGINE_URL=http://localhost:8080/yawl
export OBSERVATORY_URL=http://localhost:9090/observatory

# Run the test
./run-reinstatement-test.sh
```

### Manual Execution

```bash
# 1. Deploy workflow to YAWL engine
curl -X POST \
  -H "Content-Type: application/xml" \
  --data-binary @llc-reinstatement-workflow.xml \
  http://localhost:8080/yawl/engine/ib/deploy

# 2. Launch workflow instance
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"workflowId":"wy-reinstatement-flow","testData":{...}}' \
  http://localhost:8080/yawl/engine/ib/launch

# 3. Track GODSPEED phases
curl http://localhost:8080/yawl/engine/ib/case/{instanceId}/phase/Ψ
curl http://localhost:8080/yawl/engine/ib/case/{instanceId}/phase/Λ
# ... etc for H, Q, Ω

# 4. Get final state
curl http://localhost:8080/yawl/engine/ib/case/{instanceId}
```

## Skills Discovery

The SPARQL query file (`skills-discovery-reinstatement.rq`) contains 10 queries for discovering:

1. Payment processing skills
2. External service integration skills
3. Receipt generation skills (GODSPEED Λ phase)
4. Validation & compliance checking skills
5. Agents with required capabilities
6. MCP tools for SOS portal interaction
7. Vertical packs for legal/compliance
8. GODSPEED phase-compliant skills
9. Skills with dependency graphs
10. Full marketplace discovery

Run the queries:

```bash
curl -X POST \
  -H "Content-Type: application/sparql-query" \
  -H "Accept: application/json" \
  --data-binary @skills-discovery-reinstatement.rq \
  http://localhost:9090/observatory/sparql
```

## Receipt Schema (Λ Phase)

```yaml
type: BuildReceipt
phase: Λ
fields:
  receipt_id: "GODSPEED-WY-LLC-{YYYYMMDD}-{entity_number}-{timestamp}"
  filing_type: "agent_filing" | "self_filing"
  company_details:
    name: string
    entity_number: string
    filing_date: ISO8601
    effective_date: ISO8601
  payment:
    amount: number
    currency: "USD"
    payment_method: string
    transaction_id: string
  privacy:
    owner_name_public: boolean
    public_record_shows: string
  validation:
    annual_report_filed: boolean
    reinstatement_approved: boolean
    entity_status: string
  godspeed_phases_completed:
    psi: timestamp
    lambda: timestamp
    eta: timestamp
    theta: timestamp
    omega: timestamp
```

## Test Assertions

### All Scenarios
- ✅ Entity status changes to "active"
- ✅ All GODSPEED phases complete successfully
- ✅ Receipt generated with all required fields

### SCENARIO-001 Specific
- ✅ Owner name is private (not on public record)
- ✅ Agent's name appears on public record
- ✅ Payment amount = $417

### SCENARIO-002 Specific
- ✅ Owner name is on public record
- ✅ Payment amount = $204
- ✅ Cost savings = $213

## Monitoring & Observability

The workflow emits RDF facts to the Observatory for:

- Phase transitions (Ψ→Λ→H→Q→Ω)
- Task completion timestamps
- Validation results
- Receipt generation events
- Drift detection (if actual vs expected diverges)

Query the Observatory:

```sparql
SELECT ?phase ?completedAt ?receiptId
WHERE {
  ?fact godspeed:phase ?phase ;
        godspeed:completedAt ?completedAt ;
        godspeed:receiptId ?receiptId .
}
```

## Troubleshooting

### YAWL Engine Not Accessible
```bash
# Check YAWL status
curl http://localhost:8080/yawl/health

# Restart YAWL if needed
cd /path/to/yawl
./start.sh
```

### Workflow Deployment Failed
- Check XML syntax: `xmllint --noout llc-reinstatement-workflow.xml`
- Verify YAWL engine version compatibility (2.0+)
- Check engine logs: `/path/to/yawl/logs/yawl.log`

### Skill Discovery Returns Empty
- Verify Observatory is running: `curl http://localhost:9090/observatory/health`
- Check SPARQL endpoint: `curl -I http://localhost:9090/observatory/sparql`
- Ensure RDF ontologies are loaded

## Success Metrics

- ✅ All 3 scenarios pass
- ✅ GODSPEED phase transitions complete in < 5s total
- ✅ Receipt generation includes all required fields
- ✅ All assertions validated
- ✅ Skills discovery returns > 5 relevant skills

## Integration Points

1. **GODSPEED-ggen**: Phase-aware receipt generation and validation
2. **Skills Marketplace**: SPARQL-based skill discovery
3. **Agents Marketplace**: Agent capability matching
4. **Observatory**: RDF fact emission and drift detection
5. **MCP Tools**: Browser automation for SOS portal navigation

## Next Steps

1. Run the test suite locally
2. Integrate with CI/CD pipeline
3. Add more test scenarios (edge cases)
4. Extend skill discovery queries
5. Add performance benchmarking

## References

- [YAWL Documentation](http://www.yawlfoundation.org/)
- [GODSPEED-ggen Architecture](../../docs/GODSPEED-GGEN-ARCHITECTURE.md)
- [Skills Marketplace MVP](../../docs/SKILLS-MARKETPLACE-MVP-DESIGN.md)
- [SPARQL Ontology](../../docs/SKILLS-MARKETPLACE-SPARQL-ONTOLOGY.md)

## License

This test case is part of the GCP company operations planning workspace.
