# Week 3: Container Orchestration with k3d

**Sprint 2 Kickoff | Synchronous**

## Overview

In this lab, you move the incident tracking application from Docker Compose into Kubernetes using a local k3d cluster. k3d creates k3s nodes as Docker containers inside your team container, giving you a full Kubernetes environment. You will create a k3d cluster, use kompose to translate your Docker Compose file into Kubernetes manifests, identify and fix two critical security problems in the generated output, deploy the application, and extend the Ansible playbook.

## Learning Objectives

- Create a k3d cluster inside Docker-in-Docker and obtain a working kubeconfig
- Translate a Docker Compose file to Kubernetes manifests using kompose
- Identify and fix insecure defaults in generated manifest output
- Deploy a three-tier application to Kubernetes and verify all pods are healthy
- Extend the Ansible playbook with a k3d cluster setup role

## Prerequisites

- Week 2 complete: Docker Compose stack is running inside your team container
- Docker daemon is running inside the team container (nested Docker)
- kubectl and k3d are available or installable inside the team container

## Pulling This Week's Starter Content Into Your Team Repo

This repo (`inet4031-week03`) is instructor-provided starter/reference content for
Week 3, not something you clone standalone. Pull the pieces you need into your
team's single repo:

```bash
git remote add week3 https://github.com/INET4031-Labs/inet4031-week03.git
git fetch week3
git checkout week3/main -- manifests scripts docs
git remote remove week3
```

Do this before you start editing `manifests/` locally, or your local changes will be
silently overwritten by the checkout. Note: this week does not ship
`ansible/roles/k3d-setup` starter content, you write the k3d-setup role
yourself.

## Role Distribution

- **Scrum Master:** keeps sprint board current, unblocks dependencies, ensures cross-role coordination
- **System Admin:** leads k3d cluster creation and Ansible updates
- **QA:** runs validation checks, verifies security fixes, approves manifests before deployment
- **Developers:** write and test Kubernetes manifests, run kompose, fix issues

## Deliverables

- `manifests/` directory with all Kubernetes YAML files (Deployments, Services, Secrets)
- `ansible/roles/k3d-setup/tasks/main.yml` (new Ansible role for cluster setup)
- `ansible/site.yml` updated with k3d-setup play added
- `./scripts/check-week3.sh` runs clean
- Google Doc with completed reflection answers and screenshots

## Full Instructions

The complete step-by-step lab, including exact commands, manifest fixes, and validation checks, is in this repo's Wiki tab. This README is a reference, not a substitute.
