#!/bin/bash

# Week 3 Validation Script
# This script runs all acceptance checks for Week 3 deliverables
# Run from the repository root: ./scripts/check-week3.sh

set -e

echo "========================================="
echo "Week 3 Validation Checks"
echo "========================================="
echo ""

# Track pass/fail status
PASS_COUNT=0
FAIL_COUNT=0

# Helper function to print results
check_pass() {
    echo "[PASS] $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo "[FAIL] $1"
    ((FAIL_COUNT++))
}

check_warn() {
    echo "[WARN] $1"
}

# =========================================
# Check 1: k3d Cluster Is Running
# =========================================
echo ""
echo "Check 1: k3d Cluster Is Running"
echo "---------------------------------"

if command -v k3d &> /dev/null; then
    check_pass "k3d is installed"
else
    check_fail "k3d is not installed"
fi

if k3d cluster list 2>&1 | grep -q "myapp.*running"; then
    check_pass "k3d cluster 'myapp' is running"
else
    check_fail "k3d cluster 'myapp' is not running"
fi

# Get node count
NODE_COUNT=$(kubectl get nodes 2>/dev/null | grep -c "Ready" || echo "0")
if [ "$NODE_COUNT" -eq 3 ]; then
    check_pass "k3d cluster has exactly 3 Ready nodes"
else
    check_fail "k3d cluster does not have 3 Ready nodes (found: $NODE_COUNT)"
fi

# =========================================
# Check 2: All Pods Running
# =========================================
echo ""
echo "Check 2: All Pods Running"
echo "-------------------------"

POD_STATUS=$(kubectl get pods 2>/dev/null | grep -v "NAME" || echo "")

if [ -z "$POD_STATUS" ]; then
    check_warn "No pods found - deployment may not have started yet"
else
    RUNNING_PODS=$(echo "$POD_STATUS" | grep -c "Running" || echo "0")
    TOTAL_PODS=$(echo "$POD_STATUS" | wc -l)

    if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ]; then
        check_pass "All pods are in Running state"
    else
        check_fail "Not all pods are Running (Running: $RUNNING_PODS / Total: $TOTAL_PODS)"
        echo "Pod Status:"
        kubectl get pods
    fi

    # Check for pods with 1/1 ready
    READY_PODS=$(kubectl get pods 2>/dev/null | grep "1/1" | wc -l || echo "0")
    if [ "$READY_PODS" -gt 0 ]; then
        check_pass "$READY_PODS pods report 1/1 Ready"
    else
        check_warn "No pods report 1/1 Ready - check pod status"
    fi
fi

# =========================================
# Check 3: Credentials in Secrets, Not Deployments
# =========================================
echo ""
echo "Check 3: Credentials in Secrets, Not Deployments"
echo "------------------------------------------------"

# Check if flask Secret exists
if kubectl get secret flask-credentials &>/dev/null; then
    check_pass "Secret 'flask-credentials' exists"
else
    check_fail "Secret 'flask-credentials' not found"
fi

# Check if postgres Secret exists
if kubectl get secret postgres-credentials &>/dev/null; then
    check_pass "Secret 'postgres-credentials' exists"
else
    check_warn "Secret 'postgres-credentials' not found (verify name matches your manifests)"
fi

# Check Flask Deployment for plaintext env vars (should be empty or minimal)
FLASK_ENV=$(kubectl get deployment flask -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null || echo "")
if [ -z "$FLASK_ENV" ] || [ "$FLASK_ENV" = "[]" ]; then
    check_pass "Flask Deployment does not have inline env vars (using secretRef)"
elif echo "$FLASK_ENV" | grep -q "POSTGRES_PASSWORD\|POSTGRES_USER"; then
    check_fail "Flask Deployment contains plaintext credential env vars - use secretRef instead"
else
    check_warn "Flask Deployment has env vars but not credentials (verify fix is complete)"
fi

# =========================================
# Check 4: RollingUpdate Strategy Applied
# =========================================
echo ""
echo "Check 4: RollingUpdate Strategy Applied"
echo "----------------------------------------"

FLASK_STRATEGY=$(kubectl get deployment flask -o jsonpath='{.spec.strategy.type}' 2>/dev/null || echo "")
if [ "$FLASK_STRATEGY" = "RollingUpdate" ]; then
    check_pass "Flask Deployment uses RollingUpdate strategy"
else
    check_fail "Flask Deployment does not use RollingUpdate (current: $FLASK_STRATEGY)"
fi

# Check for maxSurge and maxUnavailable in flask deployment
FLASK_SURGE=$(kubectl get deployment flask -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null || echo "")
FLASK_UNAVAIL=$(kubectl get deployment flask -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null || echo "")

if [ -n "$FLASK_SURGE" ] && [ -n "$FLASK_UNAVAIL" ]; then
    check_pass "Flask Deployment has RollingUpdate parameters (maxSurge: $FLASK_SURGE, maxUnavailable: $FLASK_UNAVAIL)"
else
    check_warn "Flask Deployment RollingUpdate parameters not fully configured"
fi

# =========================================
# Check 5: Application Health Check
# =========================================
echo ""
echo "Check 5: Application Health Check"
echo "-----------------------------------"

if command -v curl &> /dev/null; then
    if curl -s http://localhost:8080/health &>/dev/null; then
        check_pass "Application responds to health check at http://localhost:8080/health"
    else
        check_warn "Application not responding to health check (may still be starting)"
    fi
else
    check_warn "curl not available - skipping health check"
fi

# =========================================
# Check 6: Ansible Role Exists
# =========================================
echo ""
echo "Check 6: Ansible k3d-setup Role"
echo "--------------------------------"

if [ -f "ansible/roles/k3d-setup/tasks/main.yml" ]; then
    check_pass "ansible/roles/k3d-setup/tasks/main.yml exists"
else
    check_fail "ansible/roles/k3d-setup/tasks/main.yml not found"
fi

# Check if ansible/site.yml includes k3d-setup role
if grep -q "k3d-setup" ansible/site.yml 2>/dev/null; then
    check_pass "ansible/site.yml includes k3d-setup role"
else
    check_fail "ansible/site.yml does not include k3d-setup role"
fi

# =========================================
# Check 7: Manifests Committed
# =========================================
echo ""
echo "Check 7: Manifests Directory"
echo "-----------------------------"

if [ -d "manifests" ]; then
    check_pass "manifests/ directory exists"

    MANIFEST_FILES=$(find manifests -name "*.yaml" -o -name "*.yml" | wc -l)
    if [ "$MANIFEST_FILES" -gt 0 ]; then
        check_pass "Found $MANIFEST_FILES YAML manifest files"
    else
        check_warn "No YAML files found in manifests/ directory"
    fi

    # Check for Secret files
    if [ -f "manifests/flask-secret.yaml" ] || [ -f "manifests/flask-secret.yml" ]; then
        check_pass "Flask Secret manifest found"
    else
        check_warn "Flask Secret manifest not found"
    fi

    if [ -f "manifests/postgres-secret.yaml" ] || [ -f "manifests/postgres-secret.yml" ]; then
        check_pass "PostgreSQL Secret manifest found"
    else
        check_warn "PostgreSQL Secret manifest not found"
    fi
else
    check_fail "manifests/ directory not found"
fi

# =========================================
# Summary
# =========================================
echo ""
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Warnings: (see above)"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "Status: ALL CHECKS PASSED"
    exit 0
else
    echo "Status: SOME CHECKS FAILED - Review errors above"
    exit 1
fi
