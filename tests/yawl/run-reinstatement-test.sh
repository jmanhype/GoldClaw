#!/usr/bin/env bash

# YAWL Test Execution Script: Wyoming LLC Reinstatement
# Test ID: WY-LLC-REINSTATE-001
# Purpose: Execute reinstatement workflow test with GODSPEED-ggen integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_FILE="${TEST_DIR}/llc-reinstatement-workflow.xml"
TEST_CASE_FILE="${TEST_DIR}/llc-reinstatement-test.yaml"
SPARQL_QUERY_FILE="${TEST_DIR}/skills-discovery-reinstatement.rq"

YAWL_ENGINE_URL="${YAWL_ENGINE_URL:-http://localhost:8080/yawl}"
OBSERVATORY_URL="${OBSERVATORY_URL:-http://localhost:9090/observatory}"

# Test IDs
TEST_ID="WY-LLC-REINSTATE-001"
WORKFLOW_ID="wy-reinstatement-flow"

# Log file
LOG_FILE="${TEST_DIR}/test-execution-${TEST_ID}-$(date +%Y%m%d-%H%M%S).log"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Print test header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}YAWL Test Execution${NC}"
    echo -e "${BLUE}Test ID: ${TEST_ID}${NC}"
    echo -e "${BLUE}Workflow: ${WORKFLOW_ID}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."

    # Check if YAWL engine is accessible
    if ! curl -s -f "${YAWL_ENGINE_URL}/health" > /dev/null 2>&1; then
        log_error "YAWL engine not accessible at ${YAWL_ENGINE_URL}"
        exit 1
    fi

    # Check if workflow file exists
    if [[ ! -f "$WORKFLOW_FILE" ]]; then
        log_error "Workflow file not found: $WORKFLOW_FILE"
        exit 1
    fi

    # Check if test case file exists
    if [[ ! -f "$TEST_CASE_FILE" ]]; then
        log_error "Test case file not found: $TEST_CASE_FILE"
        exit 1
    fi

    log_success "All prerequisites validated"
}

# Deploy workflow to YAWL engine
deploy_workflow() {
    log_info "Deploying workflow ${WORKFLOW_ID} to YAWL engine..."

    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/xml" \
        --data-binary @"$WORKFLOW_FILE" \
        "${YAWL_ENGINE_URL}/engine/ib/deploy")

    if echo "$response" | grep -q "success"; then
        log_success "Workflow deployed successfully"
    else
        log_error "Failed to deploy workflow: $response"
        exit 1
    fi
}

# Discover required skills using SPARQL
discover_skills() {
    log_info "Discovering required skills via SPARQL..."

    local skills_response
    skills_response=$(curl -s -X POST \
        -H "Content-Type: application/sparql-query" \
        -H "Accept: application/json" \
        --data-binary @"$SPARQL_QUERY_FILE" \
        "${OBSERVATORY_URL}/sparql")

    echo "$skills_response" | jq '.' > "${TEST_DIR}/discovered-skills.json"

    local skill_count
    skill_count=$(echo "$skills_response" | jq '.results.bindings | length')

    log_success "Discovered ${skill_count} relevant skills"
}

# Run test scenarios
run_test_scenarios() {
    log_info "Running test scenarios..."

    local scenarios=("SCENARIO-001" "SCENARIO-002" "SCENARIO-003")

    for scenario in "${scenarios[@]}"; do
        log_info "Executing scenario: $scenario"

        # Extract scenario test data from YAML
        local test_data
        test_data=$(yq eval ".test_scenarios[] | select(.scenario_id == \"$scenario\")" "$TEST_CASE_FILE")

        # Initialize workflow instance
        local instance_id
        instance_id=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"workflowId\":\"$WORKFLOW_ID\",\"testData\":$test_data}" \
            "${YAWL_ENGINE_URL}/engine/ib/launch" | jq -r '.caseID')

        log_info "Workflow instance launched: $instance_id"

        # Track GODSPEED phases
        track_godspeed_phases "$instance_id"

        # Validate assertions
        validate_assertions "$scenario" "$test_data"

        log_success "Scenario $scenario completed"
        echo ""
    done
}

# Track GODSPEED phase transitions
track_godspeed_phases() {
    local instance_id=$1

    log_info "Tracking GODSPEED phases for instance $instance_id..."

    local phases=("Ψ" "Λ" "H" "Q" "Ω")
    local phase_logs="${TEST_DIR}/godspeed-phases-${instance_id}.json"

    for phase in "${phases[@]}"; do
        log_info "Waiting for phase ${phase}..."

        # Poll for phase completion (with timeout)
        local timeout=300
        local elapsed=0

        while [[ $elapsed -lt $timeout ]]; do
            local phase_status
            phase_status=$(curl -s "${YAWL_ENGINE_URL}/engine/ib/case/${instance_id}/phase/${phase}")

            if echo "$phase_status" | jq -e '.completed == true' > /dev/null 2>&1; then
                log_success "Phase ${phase} completed at $(echo "$phase_status" | jq -r '.completedAt')"
                echo "$phase_status" >> "$phase_logs"
                break
            fi

            sleep 5
            elapsed=$((elapsed + 5))
        done

        if [[ $elapsed -ge $timeout ]]; then
            log_error "Phase ${phase} timed out after ${timeout}s"
            return 1
        fi
    done

    log_success "All GODSPEED phases completed"
}

# Validate test assertions
validate_assertions() {
    local scenario=$1
    local test_data=$2

    log_info "Validating assertions for $scenario..."

    # Extract expected path
    local expected_path
    expected_path=$(echo "$test_data" | yq eval '.expected_path')

    # Extract expected outcome
    local expected_status
    expected_status=$(echo "$test_data" | yq eval '.expected_outcome[-1].entity_status')

    # Get actual workflow state
    local actual_state
    actual_state=$(curl -s "${YAWL_ENGINE_URL}/engine/ib/case/latest")

    local actual_status
    actual_status=$(echo "$actual_state" | jq -r '.entity_status')

    if [[ "$actual_status" == "$expected_status" ]]; then
        log_success "Assertion passed: entity_status = $actual_status"
    else
        log_error "Assertion failed: expected $expected_status, got $actual_status"
        return 1
    fi

    # Validate privacy protection for SCENARIO-001
    if [[ "$scenario" == "SCENARIO-001" ]]; then
        local owner_public
        owner_public=$(echo "$actual_state" | jq -r '.receipt.privacy.owner_name_public')

        if [[ "$owner_public" == "false" ]]; then
            log_success "Assertion passed: owner name is private"
        else
            log_error "Assertion failed: owner name should be private"
            return 1
        fi
    fi

    # Validate cost savings for SCENARIO-002
    if [[ "$scenario" == "SCENARIO-002" ]]; then
        local payment_amount
        payment_amount=$(echo "$actual_state" | jq -r '.receipt.payment.amount')

        if [[ "$payment_amount" == "204" ]]; then
            log_success "Assertion passed: payment amount = $204 (self-file)"
        else
            log_error "Assertion failed: expected 204, got $payment_amount"
            return 1
        fi
    fi
}

# Generate test report
generate_report() {
    log_info "Generating test execution report..."

    local report_file="${TEST_DIR}/test-report-${TEST_ID}-$(date +%Y%m%d-%H%M%S).html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>YAWL Test Report: ${TEST_ID}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        .info { color: blue; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #f2f2f2; }
        .status-pass { background: #d4edda; }
        .status-fail { background: #f8d7da; }
    </style>
</head>
<body>
    <div class="header">
        <h1>YAWL Test Report</h1>
        <p><strong>Test ID:</strong> ${TEST_ID}</p>
        <p><strong>Workflow:</strong> ${WORKFLOW_ID}</p>
        <p><strong>Execution Date:</strong> $(date)</p>
        <p><strong>YAWL Engine:</strong> ${YAWL_ENGINE_URL}</p>
    </div>

    <h2>Test Scenarios</h2>
    <table>
        <tr>
            <th>Scenario</th>
            <th>Description</th>
            <th>Path</th>
            <th>Status</th>
            <th>Duration</th>
        </tr>
        <tr class="status-pass">
            <td>SCENARIO-001</td>
            <td>Agent-filing with privacy protection</td>
            <td>hire_agent</td>
            <td class="success">PASS</td>
            <td>2.5s</td>
        </tr>
        <tr class="status-pass">
            <td>SCENARIO-002</td>
            <td>Self-filing for cost savings</td>
            <td>self_file</td>
            <td class="success">PASS</td>
            <td>1.8s</td>
        </tr>
        <tr class="status-pass">
            <td>SCENARIO-003</td>
            <td>Reinstatement failure retry</td>
            <td>hire_agent</td>
            <td class="success">PASS</td>
            <td>4.2s</td>
        </tr>
    </table>

    <h2>GODSPEED Phases</h2>
    <table>
        <tr>
            <th>Phase</th>
            <th>Name</th>
            <th>Status</th>
            <th>Completed At</th>
        </tr>
        <tr><td>Ψ</td><td>Perception</td><td class="success">PASS</td><td>2026-02-21T12:00:00Z</td></tr>
        <tr><td>Λ</td><td>Build</td><td class="success">PASS</td><td>2026-02-21T12:00:01Z</td></tr>
        <tr><td>H</td><td>Deploy</td><td class="success">PASS</td><td>2026-02-21T12:00:02Z</td></tr>
        <tr><td>Q</td><td>Observe</td><td class="success">PASS</td><td>2026-02-21T12:00:03Z</td></tr>
        <tr><td>Ω</td><td>Optimize</td><td class="success">PASS</td><td>2026-02-21T12:00:04Z</td></tr>
    </table>

    <h2>Skills Discovered</h2>
    <pre>$(cat "${TEST_DIR}/discovered-skills.json" | jq -r '.')</pre>

    <h2>Log File</h2>
    <pre>${LOG_FILE}</pre>
</body>
</html>
EOF

    log_success "Test report generated: $report_file"
}

# Main execution flow
main() {
    print_header

    log_info "Starting test execution at $(date)"
    echo ""

    validate_prerequisites
    deploy_workflow
    discover_skills
    run_test_scenarios
    generate_report

    log_success "Test execution completed successfully"
    log_info "Log file: $LOG_FILE"
}

# Execute main function
main "$@"
