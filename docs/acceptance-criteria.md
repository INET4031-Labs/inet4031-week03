# Week 3 Acceptance Criteria

This document defines what "done" means for Week 3. QA uses this checklist before signing off on deliverables.

## Part 1: k3d Cluster Creation

### Acceptance Criteria

- [ ] k3d is installed and `k3d version` returns output
- [ ] k3d cluster named `myapp` exists
- [ ] Cluster has exactly 3 nodes: 1 control plane (server), 2 agent nodes
- [ ] All nodes show `Ready` status in `kubectl get nodes`
- [ ] LoadBalancer is configured to map port 8080 on team container to port 80 in cluster
- [ ] kubectl is configured and can reach the cluster (`kubectl get nodes` succeeds without errors)

**QA Sign-off:**

TODO: QA confirms all checks pass before proceeding to Part 2

## Part 2: Docker Compose to Kubernetes Manifests

### Acceptance Criteria: kompose Conversion

- [ ] kompose is installed and `kompose version` returns output
- [ ] `manifests/` directory exists in week-3 root
- [ ] kompose generated at least these files:
  - [ ] flask-deployment.yaml
  - [ ] postgres-deployment.yaml
  - [ ] nginx-deployment.yaml
  - [ ] flask-service.yaml
  - [ ] postgres-service.yaml
  - [ ] nginx-service.yaml
  - [ ] app-network (either NetworkPolicy or as part of Deployments)
  - [ ] db-data (PersistentVolumeClaim or volume reference)

### Acceptance Criteria: Security Fixes - Credentials

**Before applying fixes:**

- [ ] Screenshot taken showing plaintext POSTGRES_USER, POSTGRES_PASSWORD, DATABASE_URL in flask-deployment.yaml env: section
- [ ] Screenshot added to team Google Doc

**After fixes:**

- [ ] Secret files created: `flask-secret.yaml` and `postgres-secret.yaml`
- [ ] Secret files are present in `manifests/` directory
- [ ] flask-deployment.yaml uses `envFrom: secretRef` instead of inline `env:`
- [ ] postgres-deployment.yaml uses `envFrom: secretRef` instead of inline `env:`
- [ ] Verification passes: `kubectl get deployment flask -o jsonpath='{.spec.template.spec.containers[0].env}'` returns empty or non-credential vars only
- [ ] Verification passes: `kubectl get secret flask-credentials` returns the Secret successfully

### Acceptance Criteria: Deployment Strategy Fix

**Before fix:**

- [ ] Screenshot taken showing `strategy: type: Recreate` in flask-deployment.yaml
- [ ] Screenshot added to team Google Doc

**After fix:**

- [ ] flask-deployment.yaml strategy changed to:
  ```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  ```
- [ ] postgres-deployment.yaml also uses RollingUpdate strategy (if it had Recreate)
- [ ] Verification passes: `kubectl get deployment flask -o jsonpath='{.spec.strategy.type}'` returns `RollingUpdate`

**QA Sign-off:**

TODO: QA confirms all fixes are present and correct before Part 3

## Part 3: Deploy and Verify

### Acceptance Criteria: Deployment Success

- [ ] Secret manifests applied first: `kubectl apply -f manifests/flask-secret.yaml` succeeds
- [ ] Secret manifests applied first: `kubectl apply -f manifests/postgres-secret.yaml` succeeds
- [ ] All manifests applied: `kubectl apply -f manifests/` completes without error
- [ ] All pods reach `Running` state: `kubectl get pods` shows 1/1 Ready for all pods
- [ ] No pods in CrashLoopBackOff, Error, or Pending state for more than 2 minutes
- [ ] Application responds to health check: `curl http://localhost:8080/health` returns JSON response

### Acceptance Criteria: Rolling Update Verification

- [ ] Flask Deployment scaled to 2 replicas: `kubectl scale deployment flask --replicas=2`
- [ ] During scale-up, original pod remains Running while new pod starts
- [ ] After both pods are Running, no service downtime observed (health check still responds)
- [ ] Screenshot taken showing both Flask pods running side-by-side
- [ ] Screenshot added to team Google Doc

**QA Sign-off:**

TODO: QA confirms application is deployed and functional before Part 4

## Part 4: Ansible Update

### Acceptance Criteria

- [ ] Directory exists: `ansible/roles/k3d-setup/tasks/`
- [ ] File exists: `ansible/roles/k3d-setup/tasks/main.yml`
- [ ] Ansible role contents:
  - [ ] Checks if k3d is already installed
  - [ ] Installs k3d if not present (using curl script)
  - [ ] Checks if cluster exists before creating
  - [ ] Creates cluster with command: `k3d cluster create myapp --agents 2 --port "8080:80@loadbalancer"`
- [ ] `ansible/site.yml` updated to include k3d-setup role (added as new play or included in existing)
- [ ] Playbook runs without error: `ansible-playbook -i ansible/inventory ansible/site.yml` succeeds
- [ ] Playbook is idempotent: running twice produces no additional changes

**QA Sign-off:**

TODO: QA confirms Ansible additions are correct and idempotent

## Validation Checks (Automated)

These checks are run by the provided `./scripts/check-week3.sh` script.

### Check: k3d Cluster Is Running

```bash
k3d cluster list
```

Expected: one row showing `myapp` with STATUS `running`

Status: TODO

### Check: All Pods Running

```bash
kubectl get pods
```

Expected: all pods in `Running` state with `1/1` in READY column

Status: TODO

### Check: Credentials Are in Secret, Not Deployment

```bash
kubectl get deployment flask -o jsonpath='{.spec.template.spec.containers[0].env}'
kubectl get secret flask-credentials
```

Expected: first command returns empty (`[]`) or non-credential vars, second returns Secret successfully

Status: TODO

### Check: RollingUpdate Strategy Applied

```bash
kubectl get deployment flask -o jsonpath='{.spec.strategy.type}'
```

Expected: `RollingUpdate`

Status: TODO

### Check: Script Passes

```bash
./scripts/check-week3.sh
```

Expected: all checks pass

Status: TODO

## Final QA Sign-off

- [ ] All Part 1 criteria met
- [ ] All Part 2 criteria met (conversion + fixes)
- [ ] All Part 3 criteria met (deployment + verification)
- [ ] All Part 4 criteria met (Ansible updates)
- [ ] All automated validation checks pass
- [ ] Screenshots captured and in Google Doc
- [ ] All manifests committed to repository
- [ ] All Ansible changes committed to repository

**QA Lead Name:** TODO

**QA Sign-off Date:** TODO

**Any issues or concerns to note:** TODO
