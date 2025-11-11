#!/usr/bin/env bash

#
# Wander System Validation Script
# Validates complete system integration and functionality
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji indicators
CHECK="✅"
CROSS="❌"
WARN="⚠️ "
INFO="ℹ️ "

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Wander System Validation${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}${CHECK} PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}${CROSS} FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check HTTP endpoint
check_http() {
    local url="$1"
    local expected_status="${2:-200}"
    
    if command -v curl >/dev/null 2>&1; then
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        [ "$status" = "$expected_status" ]
    else
        return 1
    fi
}

# Function to check Kubernetes pod status
check_pod() {
    local app_label="$1"
    kubectl get pod -n wander-dev -l "app=$app_label" -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Running"
}

echo -e "${BLUE}=== Prerequisites Check ===${NC}"
echo ""

run_test "kubectl installed" "check_command kubectl"
run_test "docker installed" "check_command docker"
run_test "npm installed" "check_command npm"
run_test "node installed" "check_command node"
run_test "envsubst installed" "check_command envsubst"
run_test "minikube installed" "check_command minikube"

echo ""
echo -e "${BLUE}=== Kubernetes Cluster Check ===${NC}"
echo ""

run_test "Minikube is running" "minikube status | grep -q 'Running'"
run_test "kubectl can connect" "kubectl cluster-info > /dev/null 2>&1"
run_test "wander-dev namespace exists" "kubectl get namespace wander-dev > /dev/null 2>&1"

echo ""
echo -e "${BLUE}=== Pod Status Check ===${NC}"
echo ""

if kubectl get namespace wander-dev > /dev/null 2>&1; then
    run_test "PostgreSQL pod running" "check_pod postgres"
    run_test "Redis pod running" "check_pod redis"
    run_test "API pod running" "check_pod api"
    run_test "Frontend pod running" "check_pod frontend"
else
    echo -e "${YELLOW}${WARN} Skipping pod checks (namespace not found)${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 4))
fi

echo ""
echo -e "${BLUE}=== Service Health Check ===${NC}"
echo ""

if kubectl get namespace wander-dev > /dev/null 2>&1; then
    # Give services a moment if they just started
    sleep 2
    
    run_test "API health endpoint" "check_http http://localhost:4000/health 200"
    run_test "API ready endpoint" "check_http http://localhost:4000/health/ready 200"
    run_test "Frontend accessible" "check_http http://localhost:3000 200"
else
    echo -e "${YELLOW}${WARN} Skipping health checks (services not running)${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 3))
fi

echo ""
echo -e "${BLUE}=== Database Validation ===${NC}"
echo ""

if kubectl get namespace wander-dev > /dev/null 2>&1; then
    POSTGRES_POD=$(kubectl get pod -n wander-dev -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$POSTGRES_POD" ]; then
        # Check table counts
        USERS_COUNT=$(kubectl exec -n wander-dev "$POSTGRES_POD" -- psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ' || echo "0")
        TEAMS_COUNT=$(kubectl exec -n wander-dev "$POSTGRES_POD" -- psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM teams;" 2>/dev/null | tr -d ' ' || echo "0")
        PROJECTS_COUNT=$(kubectl exec -n wander-dev "$POSTGRES_POD" -- psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM projects;" 2>/dev/null | tr -d ' ' || echo "0")
        TASKS_COUNT=$(kubectl exec -n wander-dev "$POSTGRES_POD" -- psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM tasks;" 2>/dev/null | tr -d ' ' || echo "0")
        ACTIVITIES_COUNT=$(kubectl exec -n wander-dev "$POSTGRES_POD" -- psql -U postgres -d wander_dev -t -c "SELECT COUNT(*) FROM activities;" 2>/dev/null | tr -d ' ' || echo "0")
        
        run_test "Database has 5 users" "[ '$USERS_COUNT' = '5' ]"
        run_test "Database has 2 teams" "[ '$TEAMS_COUNT' = '2' ]"
        run_test "Database has 2 projects" "[ '$PROJECTS_COUNT' = '2' ]"
        run_test "Database has 6 tasks" "[ '$TASKS_COUNT' = '6' ]"
        run_test "Database has 10 activities" "[ '$ACTIVITIES_COUNT' = '10' ]"
    else
        echo -e "${YELLOW}${WARN} Skipping database checks (PostgreSQL pod not found)${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 5))
    fi
else
    echo -e "${YELLOW}${WARN} Skipping database checks (services not running)${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 5))
fi

echo ""
echo -e "${BLUE}=== File Structure Check ===${NC}"
echo ""

run_test "Root package.json exists" "[ -f package.json ]"
run_test "Shared package exists" "[ -d packages/shared ]"
run_test "API service exists" "[ -d services/api ]"
run_test "Frontend service exists" "[ -d services/frontend ]"
run_test "Database init exists" "[ -f db/init/seed.sql ]"
run_test "Makefile exists" "[ -f Makefile ]"
run_test "Documentation exists" "[ -d docs ]"
run_test "Tests exist" "[ -f tests/integration.test.ts ]"
run_test "K8s manifests exist" "[ -d infra/k8s ]"
run_test "Scripts exist" "[ -d scripts ]"

echo ""
echo -e "${BLUE}=== Documentation Check ===${NC}"
echo ""

run_test "README.md exists" "[ -f README.md ]"
run_test "SETUP.md exists" "[ -f docs/SETUP.md ]"
run_test "ARCHITECTURE.md exists" "[ -f docs/ARCHITECTURE.md ]"
run_test "API.md exists" "[ -f docs/API.md ]"
run_test "DATABASE.md exists" "[ -f docs/DATABASE.md ]"
run_test "KUBERNETES.md exists" "[ -f docs/KUBERNETES.md ]"
run_test "TROUBLESHOOTING.md exists" "[ -f docs/TROUBLESHOOTING.md ]"
run_test "CONTRIBUTING.md exists" "[ -f docs/CONTRIBUTING.md ]"
run_test "CHANGELOG.md exists" "[ -f CHANGELOG.md ]"

echo ""
echo -e "${BLUE}=== Configuration Files Check ===${NC}"
echo ""

run_test ".env.example exists" "[ -f .env.example ]"
run_test "tsconfig.base.json exists" "[ -f tsconfig.base.json ]"
run_test "eslintrc.json exists" "[ -f .eslintrc.json ]"
run_test "jest.config.js exists" "[ -f jest.config.js ]"
run_test ".gitignore exists" "[ -f .gitignore ]"
run_test ".nvmrc exists" "[ -f .nvmrc ]"

echo ""
echo -e "${BLUE}=== Docker Images Check ===${NC}"
echo ""

# Check if we're using Minikube's Docker
if minikube status > /dev/null 2>&1; then
    MINIKUBE_DOCKER=1
    eval $(minikube docker-env 2>/dev/null)
fi

run_test "wander-api image exists" "docker images | grep -q wander-api"
run_test "wander-frontend image exists" "docker images | grep -q wander-frontend"
run_test "wander-postgres image exists" "docker images | grep -q wander-postgres"

echo ""
echo -e "${BLUE}=== Results Summary ===${NC}"
echo ""

echo -e "Tests Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests:   $TOTAL_TESTS"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${CHECK} All validation tests passed!${NC}"
    echo ""
    echo -e "${BLUE}System is ready for use.${NC}"
    exit 0
else
    PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}${WARN} Some tests failed (${PASS_RATE}% pass rate)${NC}"
    echo ""
    echo -e "${BLUE}Recommendations:${NC}"
    echo "1. Run 'make dev' to start all services"
    echo "2. Check 'make status' for pod status"
    echo "3. Review 'make logs' for error messages"
    echo "4. See docs/TROUBLESHOOTING.md for common issues"
    exit 1
fi

