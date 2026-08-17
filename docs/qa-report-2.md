# QA Report: Sprint 2 (Week 3)

**QA Lead:** TODO

**Report Date:** TODO

**Sprint:** Sprint 2 (Week 3: Container Orchestration with k3d)

---

## Executive Summary

TODO: One or two sentences summarizing the state of Week 3 deliverables. Are all acceptance criteria met? Are there any blockers or concerns?

---

## Test Coverage Summary

### Part 1: k3d Cluster Creation

**Tests Run:**

- [ ] k3d installation verification
- [ ] Cluster existence check
- [ ] Node count and status verification
- [ ] LoadBalancer port mapping verification
- [ ] kubectl connectivity check

**Summary:** TODO: What worked? What failed? Any retries needed?

**Confidence Level:** TODO: (High / Medium / Low)

---

### Part 2: Docker Compose to Kubernetes Manifests

**Tests Run:**

- [ ] kompose installation verification
- [ ] Manifest file generation (all required files present)
- [ ] Plaintext credential identification (before fix)
- [ ] Credential fix verification (Secrets created, Deployments use envFrom)
- [ ] Recreate strategy identification (before fix)
- [ ] RollingUpdate strategy verification (after fix)

**Plaintext Credential Issues Found:**

TODO: List any env vars still visible as plaintext in Deployments

```
Example: flask-deployment.yaml line 25 still shows POSTGRES_PASSWORD: changeme
```

**Strategy Issues Found:**

TODO: List any Deployments still using Recreate strategy

```
Example: nginx-deployment.yaml still uses strategy: type: Recreate
```

**Summary:** TODO: Were all security fixes successfully applied?

**Confidence Level:** TODO: (High / Medium / Low)

---

### Part 3: Deploy and Verify

**Tests Run:**

- [ ] Secret manifest application (flask-secret.yaml)
- [ ] Secret manifest application (postgres-secret.yaml)
- [ ] Full manifests deployment
- [ ] Pod startup and readiness
- [ ] Application health check
- [ ] Rolling update behavior during scale-up

**Pod Status at Test Time:**

```
TODO: Paste kubectl get pods output
```

**Health Check Result:**

```bash
curl http://localhost:8080/health
```

Result: TODO

**Rolling Update Behavior:**

TODO: Describe what happened when scaling Flask to 2 replicas:
- Did the first pod stay Running? (Yes/No)
- Did the second pod start without bringing the first one down? (Yes/No)
- Did the application remain healthy during the update? (Yes/No)

**Issues Found During Deployment:**

TODO: List any problems encountered:
- Pods stuck in Pending (if so, why?)
- Pods in CrashLoopBackOff (if so, check logs: kubectl logs <pod-name>)
- Service not responding (if so, check LoadBalancer: kubectl get svc)
- Database connectivity issues (if so, check environment variables)

**Summary:** TODO: Is the application deployed and functional?

**Confidence Level:** TODO: (High / Medium / Low)

---

### Part 4: Ansible Update

**Tests Run:**

- [ ] k3d-setup role directory structure
- [ ] main.yml contents (k3d install task, cluster creation task)
- [ ] ansible/site.yml includes k3d-setup role
- [ ] Playbook executes without error on first run
- [ ] Playbook is idempotent (no changes on second run)

**First Playbook Run Output:**

```
TODO: Paste relevant lines from ansible-playbook output
```

**Second Playbook Run Output (idempotency check):**

```
TODO: Paste PLAY RECAP showing changed=0
```

**Issues Found:**

TODO: List any Ansible errors or warnings

**Summary:** TODO: Is the Ansible role correctly written and idempotent?

**Confidence Level:** TODO: (High / Medium / Low)

---

## Validation Check Results

### Automated Script: ./scripts/check-week3.sh

**Script Status:** TODO: (Passing / Failing)

**Output:**

```
TODO: Paste full output of check-week3.sh
```

**Individual Check Results:**

1. k3d Cluster Running: TODO: (Pass / Fail)
2. All Pods Running: TODO: (Pass / Fail)
3. Credentials in Secret: TODO: (Pass / Fail)
4. RollingUpdate Strategy: TODO: (Pass / Fail)

---

## Screenshots and Evidence

**Required Screenshots in Google Doc:**

- [ ] Screenshot 1: kompose output showing plaintext env vars and Recreate strategy (before fixes)
- [ ] Screenshot 2: kubectl get pods showing all pods Running
- [ ] Screenshot 3: Rolling update in progress (two Flask pods visible)
- [ ] Screenshot 4: ./scripts/check-week3.sh passing

**Google Doc Link:** TODO

---

## Risk Assessment

### Critical Issues (Blocking Deliverables)

TODO: List any issues that prevent the lab from being marked complete:

Example:
- k3d cluster fails to start: prevented team from testing Kubernetes deployment
- Plaintext passwords still visible in Deployments: security fix not applied

**Resolution:** TODO

### Medium Issues (Quality Concerns)

TODO: List issues that work but have quality concerns:

Example:
- Playbook takes 5 minutes to run (idempotency is correct but performance is slow)
- Certificate warnings when accessing LoadBalancer (TLS not configured)

**Resolution:** TODO

### Low Issues (Documentation / Polish)

TODO: List minor issues:

Example:
- Comments missing from manifests
- No description of what each Secret contains

**Resolution:** TODO

---

## Team Coordination Notes

**Cross-Role Dependencies:**

TODO: Did any role depend on another role's work? Did dependencies get cleared promptly?

Example:
- Developers created manifests, then System Admin applied Ansible changes
- QA had to wait for Developers to fix strategy before validating

**Blockers and How They Were Resolved:**

TODO: What got stuck? How did the team resolve it?

---

## Lessons Learned

**What went well this week:**

TODO: Positive observations about the process or deliverables

**What could be improved next week:**

TODO: Suggestions for smoother workflow, clearer documentation, earlier communication, etc.

---

## Sign-Off

**QA Lead:** TODO (Signature or confirmation)

**Date:** TODO

**Status:** TODO: (APPROVED / APPROVED WITH CONCERNS / NOT APPROVED)

**Comments:**

TODO: Any final remarks about this week's deliverables
