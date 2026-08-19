## Week 3: Container Orchestration with k3d

**Sprint 2 Kickoff | Synchronous**

> **Assumption:** This lab requires k3d to create k3s nodes as Docker containers inside your team container. This depends on `--privileged` mode being available on the university's container platform. If your team's container does not support nested Docker, k3d cannot create its cluster nodes and this lab will not work as written. Confirm with your instructor before continuing.

### Overview

In this lab, you move the incident tracking application from Docker Compose into Kubernetes, running on a local k3d cluster inside your team container. k3d creates k3s nodes as Docker containers, giving you a full Kubernetes environment without a separate cluster. You will use kompose to translate your Docker Compose file into Kubernetes manifests, identify and fix two problems in the generated output, and deploy a working application into the cluster. After completing this lab, you will have the incident tracker running in Kubernetes with fixed manifests committed to your repository, and the k3d setup added to your Ansible playbook.

### Learning Objectives

- Create a k3d cluster inside a Docker-in-Docker environment and obtain a working kubeconfig
- Translate a Docker Compose file to Kubernetes manifests using kompose
- Identify and fix insecure defaults in generated manifest output (plaintext credentials and Recreate strategy)
- Deploy a three-tier application to Kubernetes and verify all pods are healthy
- Extend the Ansible playbook with a k3d cluster setup role

### Prerequisites

- Week 2 complete: Docker Compose stack is running inside your team container
- Docker daemon is running inside the team container (nested Docker)
- `kubectl` and `k3d` available in the container, or installable

### Sprint Review: Sprint 1

**Step 1.** Open your team's GitHub project board. Move all completed Sprint 1 items to Done. For any incomplete items, add a one-sentence note explaining what was not finished.

**Step 2.** Each team member answers these three questions. The Scrum Master facilitates. Record answers in your Google Doc under "Sprint 1 Close."

- What did you contribute to Sprint 1?
- What is the most important thing the team shipped?
- What would you do differently if Sprint 1 started again?

**Step 3.** Run the container state checkpoint.

```bash
docker ps
docker compose -f week-2/docker-compose.yml ps
git log --oneline -5
```

Paste the output into your Google Doc under "Sprint 2 Kickoff -- Environment State."

### Sprint 2 Kickoff

**Step 4.** Assign Sprint 2 roles from your rotation schedule. Record the assignments.

**Step 5.** Create a Sprint 2 milestone on your GitHub project board. Add Week 3 deliverable items as issues before proceeding.

---

### Part 1: Create a k3d Cluster

> **Background:** k3d is a wrapper that runs k3s (a lightweight Kubernetes distribution) inside Docker containers. When you create a k3d cluster inside your team container, k3d launches Docker containers that act as k3s nodes. Your team container's Docker daemon manages those node containers. This gives you a real Kubernetes API server and full `kubectl` access without needing a separate VM or cloud environment.

**Step 6.** Install k3d inside the team container if it is not already available.

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

Verify the installation.

```bash
k3d version
```

You should see version output starting with `k3d version`.

**Step 7.** Create a k3d cluster. The `--port` flag maps port 80 on the LoadBalancer to port 8080 on the team container host.

```bash
k3d cluster create myapp --agents 2 --port "8080:80@loadbalancer"
```

This takes one to two minutes. k3d creates three containers inside your team container: one server node and two agent nodes.

**Step 8.** Verify all cluster nodes are ready.

```bash
kubectl get nodes
```

Expected output: three rows, all with `Ready` in the STATUS column.

```
NAME                  STATUS   ROLES                  AGE   VERSION
k3d-myapp-server-0    Ready    control-plane,master   2m    v1.x.x
k3d-myapp-agent-0     Ready    <none>                 2m    v1.x.x
k3d-myapp-agent-1     Ready    <none>                 2m    v1.x.x
```

If any node is `NotReady` after two minutes, run `kubectl describe node <node-name>` to see the error.

**Discussion (add to Google Doc):** k3d runs k3s nodes as Docker containers inside your team container. What resource does this create competition for? What would you check first if the cluster nodes became `NotReady` unexpectedly?

---

### Part 2: Translate Docker Compose to Kubernetes Manifests

> **Background:** kompose converts a Docker Compose file into Kubernetes YAML manifests. However, kompose generates output based on what it sees in the Compose file, carrying forward any problems present there. Two problems appear in almost every kompose output and must be fixed before the manifests are applied: plaintext environment variables and the Recreate deployment strategy.

**Step 9.** Install kompose inside the team container.

```bash
curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose
chmod +x kompose
mv kompose /usr/local/bin/kompose
```

Verify:

```bash
kompose version
```

**Step 10.** Create a `manifests/` directory and run kompose against the Week 2 Docker Compose file.

```bash
mkdir -p manifests
cd manifests
kompose convert -f ../week-2/docker-compose.yml
```

You should see several files created: Deployments and Services for each service.

**Step 11.** Before applying anything, examine the generated Deployment for your Flask service.

```bash
cat flask-deployment.yaml
```

Find two problems:

1. **Plaintext credentials**: Look for `env:` blocks containing `POSTGRES_USER`, `POSTGRES_PASSWORD`, or `DATABASE_URL` with literal values. If present in plain text, they are visible to anyone who can read the manifest.

2. **Recreate strategy**: Look for `strategy: type: Recreate`. This takes the service offline completely before starting the new version during a rollout.

**Take a screenshot showing both issues. Add it to your team's Google Doc.**

**Discussion (add to Google Doc):** kompose translated your Compose file literally. If your Compose file had problems, they appear in the Kubernetes output unchanged. What does this tell you about treating automatically generated infrastructure code as production-ready without review?

**Step 12.** Fix Problem 1: Move plaintext credentials to a Kubernetes Secret. Create `manifests/flask-secret.yaml`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: flask-credentials
  namespace: default
type: Opaque
stringData:
  POSTGRES_USER: appuser
  POSTGRES_PASSWORD: changeme
  DATABASE_URL: postgresql://appuser:changeme@postgres:5432/statustracker
```

> **Note:** Kubernetes Secrets are base64-encoded but not encrypted at rest by default. In production, credentials come from a secrets manager. You will improve on this in Week 7.

**Step 13.** Update the Flask Deployment to use the Secret instead of inline environment variables. Find the `env:` block in `flask-deployment.yaml` and replace it with:

```yaml
        envFrom:
          - secretRef:
              name: flask-credentials
```

Remove any inline `env:` entries that reference database credentials.

**Step 14.** Apply the same fix to the PostgreSQL Deployment: create a separate Secret and update `postgres-deployment.yaml` to use `envFrom`.

**Step 15.** Fix Problem 2: Change the deployment strategy. Open `flask-deployment.yaml` and change:

```yaml
  strategy:
    type: Recreate
```

to:

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

**Discussion (add to Google Doc):** RollingUpdate replaces pods gradually, keeping the old version running until the new one is healthy. In what production scenario would you intentionally choose Recreate over RollingUpdate?

---

### Part 3: Deploy and Verify

**Step 16.** Apply the Secret manifests first.

```bash
kubectl apply -f manifests/flask-secret.yaml
kubectl apply -f manifests/postgres-secret.yaml
```

**Step 17.** Apply all remaining manifests.

```bash
kubectl apply -f manifests/
```

**Step 18.** Watch the pods come up.

```bash
kubectl get pods --watch
```

Wait until all pods show `Running`. Press `Ctrl+C` once they are stable.

**Step 19.** Test the application through the LoadBalancer.

```bash
curl http://localhost:8080/health
```

Expected: a JSON response indicating the service is up.

**Step 20.** Demonstrate a rolling update by scaling the Flask Deployment.

```bash
kubectl scale deployment flask --replicas=2
kubectl get pods --watch
```

Watch the second pod come up without the first one going down. Press `Ctrl+C` when both pods are running.

**Discussion (add to Google Doc):** If the PostgreSQL pod crashes, Kubernetes restarts it automatically. What does Kubernetes NOT recover automatically? What would a production team add to make PostgreSQL data safe?

---

### Part 4: Ansible Update

**Step 21.** Create the k3d-setup role in the Ansible directory.

```bash
mkdir -p ansible/roles/k3d-setup/tasks
```

**Step 22.** Create `ansible/roles/k3d-setup/tasks/main.yml`.

```yaml
---
- name: Check if k3d is installed
  command: which k3d
  register: k3d_check
  failed_when: false
  changed_when: false

- name: Install k3d
  shell: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  when: k3d_check.rc != 0

- name: Check if k3d cluster exists
  command: k3d cluster list
  register: cluster_list
  changed_when: false

- name: Create k3d cluster if not present
  command: k3d cluster create myapp --agents 2 --port "8080:80@loadbalancer"
  when: "'myapp' not in cluster_list.stdout"
```

**Step 23.** Add the k3d-setup role to `ansible/site.yml`.

```yaml
- name: Set up k3d cluster
  hosts: localhost
  connection: local
  become: yes

  roles:
    - k3d-setup
```

**Step 24.** Run the playbook to verify it executes cleanly.

```bash
ansible-playbook -i ansible/inventory ansible/site.yml
```

**Step 25.** Commit all changes.

```bash
git add manifests/ ansible/
git commit -m "feat: add k8s manifests with fixed credentials and strategy; add k3d-setup role"
git push origin main
```

---

### Storage Check

```bash
df -h
docker system df
```

> **Important:** k3d creates k3s node containers using a separate containerd image store. These images are NOT visible to `docker system df`. Running `docker system prune` will not reclaim this space. This is a distinct storage pool that grows as you pull Kubernetes-managed container images.

---

### Validation Checks

#### Validation Check: k3d Cluster Is Running

```bash
k3d cluster list
```

Expected: one row showing `myapp` with STATUS `running`.

#### Validation Check: All Pods Running

```bash
kubectl get pods
```

Expected: all pods in `Running` state with `1/1` in READY.

#### Validation Check: Credentials Are in a Secret, Not a Deployment

```bash
kubectl get deployment flask -o jsonpath='{.spec.template.spec.containers[0].env}'
```

Expected output: empty (`[]`) or output showing only non-credential environment variables.

Also verify the Secret exists:

```bash
kubectl get secret flask-credentials
```

#### Validation Check: RollingUpdate Strategy Applied

```bash
kubectl get deployment flask -o jsonpath='{.spec.strategy.type}'
```

Expected output: `RollingUpdate`

#### Validation Check: Check Script Passes

```bash
./scripts/check-week3.sh
```

---

### Deliverables

- `manifests/` directory committed with all Kubernetes manifests (Deployments, Services, Secrets)
- Evidence of fixing plaintext env vars: Secret manifest present, Deployment uses `envFrom`
- Evidence of strategy change: `flask-deployment.yaml` shows `RollingUpdate`
- `ansible/site.yml` updated with k3d-setup play
- `ansible/roles/k3d-setup/tasks/main.yml` committed
- `./scripts/check-week3.sh` runs clean

**Screenshot requirements:**

- **Screenshot 1:** kompose output showing the two issues (plaintext env vars and Recreate strategy) before fixes
- **Screenshot 2:** `kubectl get pods` showing all pods Running
- **Screenshot 3:** rolling update in progress (two Flask pods visible)
- **Screenshot 4:** `./scripts/check-week3.sh` passing

---

### Reflection Questions (Answer in Google Doc)

1. kompose generated manifests from your Compose file and both were insecure. What assumptions did kompose make that were wrong? Why doesn't a translation tool automatically correct these?
2. RollingUpdate versus Recreate: in what real-world scenario would you intentionally choose Recreate over RollingUpdate, even knowing it causes downtime?
3. Your three-tier application now has Deployments for each tier. If your PostgreSQL pod crashes, Kubernetes restarts it automatically. What does Kubernetes NOT recover automatically?
4. You moved secrets from a `.env` file to Kubernetes Secrets. Kubernetes Secrets are base64-encoded by default, not encrypted. What does this mean for your security posture, and what would a production team do differently?
5. (Extend) Your k3d cluster runs inside your team container. What happens to the cluster if the team container restarts? Is this acceptable for this class? Would it be acceptable in production?

---

### Sprint Backlog: Preparing for Week 4

Week 4 is asynchronous. Before leaving today, the Scrum Master ensures the following tickets are open:

- Install and configure OpenTofu in the team container
- Write `main.tf` with Kubernetes provider and local backend
- Define Deployments and Services as OpenTofu resources
- Run `tofu plan` and `tofu apply`
- Add k3s resilience validation steps
- Add opentofu-setup role to `ansible/site.yml`
- Update Google Doc with Week 4 reflections and storage check

---

---

