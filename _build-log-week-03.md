# Build Log: Week 3 Student Repository Scaffold

**Date Created:** August 14, 2026

**Phase:** Phase 1 Scaffold Creation

**Week:** Week 3 (Sprint 2 Kickoff - Synchronous)

**Scope:** Student repository scaffolding for container orchestration with k3d

---

## Summary

Created complete Week 3 student repository scaffold under `Student Repositories/week-03/` following the INET 4031 course structure. All files include TODO markers for student work, and the build-log documents every assumption made and ambiguity encountered.

---

## File Structure Created

```
Student Repositories/week-03/
├── README.md                    (Week overview, architecture notice, role distribution)
├── docs/
│   ├── sprint-2-retrospective.md (blank template with section structure)
│   ├── environment-log.md        (storage tracking and cluster logs)
│   ├── acceptance-criteria.md    (comprehensive QA checklist)
│   └── qa-report-2.md            (blank template for QA findings)
├── manifests/
│   ├── README.md                 (guide to manifest fixes and validation)
│   ├── MANIFESTS-CHECKLIST.md    (verification checklist for kompose output)
│   ├── flask-secret.yaml         (TODO: template for credentials)
│   ├── postgres-secret.yaml      (TODO: template for credentials)
│   ├── flask-deployment.yaml     (template showing before/after fixes)
│   └── postgres-deployment.yaml  (template showing fix pattern)
└── scripts/
    └── check-week3.sh            (automated validation checks)
```

---

## Assumptions Made

### Architecture Assumptions

**ASSUMPTION 1: Docker-in-Docker with Nested k3d**

The lab assumes the university's container platform allows `--privileged` mode. This is required for:
- Docker daemon running inside the team container
- k3d creating k3s node containers inside that daemon

**Status:** UNCONFIRMED by professor

**Source:** Lab directions state: "Every week from Week 3 onward depends on the university's container platform permitting `--privileged` mode for Docker containers. This has not been confirmed by the professor."

**Mitigation:** README.md includes prominent notice requiring professor confirmation before starting.

### Prerequisite Assumptions

**ASSUMPTION 2: Week 2 Deliverables Exist**

Week 3 prerequisites state:
- "Week 2 complete: Docker Compose stack is running inside your team container"
- "Application source code provided by the professor is available"

This scaffold does NOT generate Week 2 files (docker-compose.yml, week-2/app/, etc.). It assumes these exist and are working before students start Week 3.

**Mitigation:** README.md lists prerequisites clearly. Week 3 Part 1 does not require Week 2 files; Part 2 begins by running kompose against Week 2 docker-compose.yml.

**ASSUMPTION 3: kubectl and Docker Already Installed**

The lab states kubectl and k3d are "available or installable" inside the team container. This scaffold assumes installation steps in Part 1 and Part 4 (Ansible) are sufficient.

**Mitigation:** Part 1 Step 6 installs k3d explicitly before use. Part 4 adds k3d installation to Ansible so it's reproducible.

### Tool and Command Assumptions

**ASSUMPTION 4: kompose Output Structure**

This scaffold assumes kompose generates manifests with:
- Separate files for each Deployment, Service
- Environment variables embedded directly in Deployment specs
- Deployment strategy defaulting to `Recreate`
- Possible inline volume definitions

**Source:** Lab directions Part 2 Step 10-11 identify these exact patterns.

**Mitigation:** MANIFESTS-CHECKLIST.md documents all expected files and common patterns.

**ASSUMPTION 5: Kubernetes Secret Naming Convention**

The scaffold assumes Secret names match deployment references:
- `flask-credentials` for Flask environment variables
- `postgres-credentials` for PostgreSQL environment variables

**Reasoning:** Lab directions Part 2 Step 12 specifies this naming in the example.

**Mitigation:** All manifest templates use these names consistently.

**ASSUMPTION 6: LoadBalancer Service Port Mapping**

Part 1 Step 7 maps port 8080 on team container to port 80 in cluster:
```bash
k3d cluster create myapp --agents 2 --port "8080:80@loadbalancer"
```

This assumes:
- Port 8080 is available on team container
- Nginx/Ingress routes traffic to port 80 in cluster
- Health check endpoint is reachable at http://localhost:8080/health

**Mitigation:** If port conflict occurs, students will see error from k3d cluster create. check-week3.sh attempts the health check and warns if unreachable.

---

## Ambiguities Encountered and Resolutions

### Ambiguity 1: Which Files Does kompose Generate?

**Problem:** Lab directions Part 2 Step 10 say "You should see several files created: Deployments and Services for each service" but do not specify exact filenames or whether NetworkPolicy/PersistentVolumeClaim files are generated.

**Source:** kompose behavior varies based on Docker Compose file structure. There is no guarantee every deployment will generate identical sets of files.

**Resolution:** 
- MANIFESTS-CHECKLIST.md lists "expected" files based on typical kompose output
- Marked as "TODO" because actual output depends on week-2/docker-compose.yml
- Includes note: "Your exact files may differ based on your Compose file structure"
- Provides verification steps instead of assuming file names

### Ambiguity 2: Secret Names in PostgreSQL Deployment

**Problem:** Lab directions Part 2 Step 14 say "Apply the same fix to the PostgreSQL Deployment" but do not specify the exact Secret name or reference format.

**Source:** Step 12 names Flask Secret as "flask-credentials" but Step 14 does not state whether postgres Secret should be "postgres-credentials" or something else.

**Resolution:**
- Scaffold template uses "postgres-credentials" consistently
- acceptance-criteria.md explicitly checks for "flask-credentials" (as specified in lab)
- Scripts check both Secret names, and QA can verify which names students actually used

### Ambiguity 3: RollingUpdate Parameters

**Problem:** Lab directions Part 2 Step 15 specify RollingUpdate but do not clarify optimal values for maxSurge and maxUnavailable.

**Source:** Step 15 shows:
```yaml
maxSurge: 1
maxUnavailable: 0
```

These values maintain availability (no pods offline during update, up to 1 extra pod). No discussion of trade-offs.

**Resolution:**
- Scaffold templates hardcode these values (maxSurge: 1, maxUnavailable: 0)
- QA report template asks whether team considered the trade-off (availability vs. resource usage)
- Reflection questions in lab prompt discussion of Recreate vs. RollingUpdate scenarios

### Ambiguity 4: Storage Tracking (Containerd vs. Docker)

**Problem:** Lab directions state: "k3d creates k3s node containers using a separate containerd image store. These images are NOT visible to `docker system df`."

This means students cannot directly measure k3d storage consumption with Docker tools.

**Resolution:**
- environment-log.md explains the distinction clearly
- Documents both `df -h` (filesystem) and `docker system df` (Docker daemon)
- Notes that containerd storage is separate and may not be directly visible
- Suggests watching `/var/lib/rancher/k3d/` if available

### Ambiguity 5: Validation Script vs. Manual Checks

**Problem:** Lab directions list both manual validation checks (Part 3) and automated validation (a check-week3.sh script mentioned but not provided in detail).

**Source:** Validation Checks section lists specific kubectl commands but does not define what the script should do.

**Resolution:**
- check-week3.sh implements all listed validation checks
- Provides both PASS/FAIL and WARN status levels
- Counts successes/failures and exits with status code (0 for pass, 1 for fail)
- Includes detailed output to help QA diagnose issues

### Ambiguity 6: Pre-Sprint 2 Ceremony Timing

**Problem:** Lab directions describe "Sprint Review: Sprint 1" before "Sprint 2 Kickoff" but the timing is ambiguous. Does this happen at the end of lab or separate session?

**Source:** Sections titled "Sprint Review: Sprint 1" and "Sprint 2 Kickoff" but no guidance on when each occurs relative to student work time.

**Resolution:**
- sprint-2-retrospective.md includes both Sprint 1 close and Sprint 2 kickoff sections
- Instruction is implicit: "this section is completed AFTER Week 3 lab work is finished"
- Students fill in Sprint 1 review at start, Sprint 2 close at end
- Reflects the sprint rhythm described in course overview (each week-lab is one sprint cycle)

### Ambiguity 7: Manifest Files to Commit

**Problem:** Lab directions Part 4 Step 25 say "git add manifests/" but does not specify whether to commit generated manifests or just the fixed versions.

**Source:** In a real git workflow, developers would regenerate manifests with kompose, then commit fixes. The scaffold must allow this without pre-populating all files.

**Resolution:**
- flask-secret.yaml and postgres-secret.yaml are template stubs with TODO markers
- flask-deployment.yaml and postgres-deployment.yaml are partial templates showing before/after
- MANIFESTS-CHECKLIST.md explains this is scaffolding, actual files come from kompose
- README.md and comments make clear that manifests/ will be populated during the lab

---

## Cross-Week Dependencies

### Week 2 Dependency

Week 3 requires Week 2's Docker Compose file to run kompose (Part 2 Step 10):
```bash
kompose convert -f ../week-2/docker-compose.yml
```

**Impact:** If week-2/docker-compose.yml does not exist or is malformed, kompose will fail.

**Mitigation:** Prerequisite check in README.md. Part 1 must complete before Part 2.

### Week 4 Dependency

Week 3 creates k3d cluster and Kubernetes manifests. Week 4 will use these with OpenTofu:
- K3d cluster must be running (Week 3 Part 1)
- kubectl must be configured (Week 3 Part 1)
- Kubernetes Secrets and Deployments must exist (Week 3 Part 3)

**Impact:** If Week 3 manifests are not correctly deployed, Week 4 will fail to manage infrastructure with OpenTofu.

**Mitigation:** Comprehensive validation checks ensure all pods are running before Week 4 starts.

### Ansible Thread (Weeks 1-4)

Weeks 1-4 each add tools to ansible/site.yml. Week 3 adds the k3d-setup role.

**Expected state at Week 3 start:**
- ansible/site.yml exists with baseline tasks from Week 1
- ansible/site.yml may include app-stack role from Week 2

**Expected state at Week 3 end:**
- ansible/site.yml includes baseline + app-stack + k3d-setup roles
- Ansible is idempotent (running twice produces no changes on second run)

**Mitigation:** Part 4 explicitly adds k3d-setup as a new play, not overwriting existing roles.

---

## Writing and Structure Decisions

### Role Distribution

Week 3 is explicitly structured so no single role completes the lab solo:

**System Admin:** Part 1 (k3d cluster) + Part 4 (Ansible)
**Developers:** Part 2 (manifest generation and fixes)
**QA:** Part 3 (validation) + all check scripts
**Scrum Master:** Board updates, unblocking

**Verified against:** Documents/Sprint_Structure_Layout.md (skill requirement)

### Document Templates

Following skill rules, every week repo includes:
- [ ] `docs/sprint-2-retrospective.md` (blank template) - CREATED
- [ ] `docs/environment-log.md` (blank template with guidance) - CREATED
- [ ] `docs/acceptance-criteria.md` (comprehensive checklist) - CREATED
- [ ] `docs/qa-report-2.md` (blank template) - CREATED

All templates include TODO markers and structure to guide student work.

### OpenTofu Naming

Week 3 does not introduce OpenTofu (that is Week 4). No OpenTofu references in this scaffold.

**Verified:** No links to developer.hashicorp.com, no use of "Terraform" term (skill requirement).

### Plain Language

All student-facing text avoids:
- Em dashes (converted to commas or periods)
- Expert-to-expert jargon (explained Docker-in-Docker, Recreate vs. RollingUpdate, etc.)
- Assumptions about prior k3d/Kubernetes knowledge

**Verified:** README.md and all manifest comments use step-following language.

---

## Known Issues and Future Refinement

### Issue 1: Generated Manifest Filenames

The scaffold assumes kompose generates specific filenames (flask-deployment.yaml, postgres-service.yaml, etc.). If kompose output differs, students may be confused by scaffold templates.

**Mitigation:** MANIFESTS-CHECKLIST.md clearly states "your exact files may differ" and provides generic troubleshooting.

**Future:** Phase 2 QA agent should verify kompose actually generates these files and update templates if needed.

### Issue 2: Container Resource Constraints

k3d creates Docker containers inside the team container. If the team container has insufficient resources (CPU/memory), k3d nodes may fail to start or pods may be evicted.

**Current guidance:** None explicit in scaffold (this is environmental, not part of the lab).

**Mitigation:** environment-log.md's storage tracking will reveal resource issues when storage fills up.

**Future:** Week 4 or later labs should add resource monitoring guidance.

### Issue 3: k3d Cluster Persistence

The scaffold mentions k3d clusters persist as Docker containers but does not explicitly test what happens if the team container restarts.

**Current guidance:** sprint-2-retrospective.md asks students to discuss this.

**Mitigation:** Check-week3.sh can be run post-restart to verify cluster state.

**Future:** Phase 2 should verify this works as expected and update docs if behavior differs.

---

## Testing Checklist for Phase 2 QA

When the Phase 2 QA agent reviews this scaffold, verify:

- [ ] All template files have clear TODO markers
- [ ] No actual secrets or credentials are committed (only placeholders)
- [ ] README.md includes `--privileged` mode assumption notice
- [ ] Four role-artifact docs exist and match the sprint cycle
- [ ] check-week3.sh script runs without syntax errors
- [ ] MANIFESTS-CHECKLIST.md accurately describes typical kompose output
- [ ] Ansible role template (Part 4) matches Week 1-2 structure
- [ ] No em dashes in student-facing text
- [ ] No links to developer.hashicorp.com or Terraform terms
- [ ] Role distribution verified against Sprint_Structure_Layout.md
- [ ] Cross-week dependencies (Week 2 docker-compose.yml, Week 4 OpenTofu) noted
- [ ] Ambiguities logged and resolutions explained

---

## References

- Lab Directions: `Documents/INET 4031 Lab Directions - Full Curriculum (Proposed).md`, Week 3 section
- Sprint Structure: `Documents/Sprint_Structure_Layout.md`
- Course Rules Skill: `inet4031-course-rules`
- Prerequisite: Week 2 complete (docker-compose.yml, week-2/app/)

---

## Sign-Off

**Scaffold Created By:** Claude Agent (Week 3 Builder)

**Completion Date:** August 14, 2026

**Status:** READY FOR PHASE 2 QA REVIEW

All assumptions documented. All ambiguities resolved with explanation. All files present and tagged with TODO markers for student work.
