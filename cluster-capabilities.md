# Local Cluster Setup Capabilities

This project is tailored to bootstrap and pre-configure a local Kubernetes cluster tailored for development, testing, and AI agent workloads. It primarily targets the **Docker Desktop** Kubernetes context.

The local cluster setup is now fully automated and declarative using a **GitOps** approach with **ArgoCD**, replacing the legacy imperative scripts.

## Core Capabilities and Installed Components

### GitOps Core (ArgoCD & App of Apps)
- **Tool:** [ArgoCD](https://argo-cd.readthedocs.io/)
- **Purpose:** Acts as the declarative GitOps engine that synchronizes the cluster state directly from this Git repository.
- **Config:** A root "App of Apps" (`argocd/root-app.yaml`) manages the installation sequence and sync of all other applications stored under `argocd/apps/`.

### 1. Identity & Auth (Dex)
- **Tool:** [Dex Identity Provider](https://dexidp.io/) (`dexidp`)
- **Purpose:** Acts as a federated OpenID Connect provider to handle authentication for cluster services and applications.
- **Config:** Deployed declaratively via ArgoCD (`argocd/apps/dex.yaml`) using settings from `helm/dex-values.yaml`.

### 2. AI / Agent Execution (Kagent)
- **Tool:** Kagent (`ghcr.io/kagent-dev/kagent`)
- **Purpose:** Deploys an AI agent capability natively into the cluster. It requires a valid `GOOGLE_API_KEY` to configure Gemini as the default AI provider.
- **Config:** CRDs and the Kagent controller are deployed via ArgoCD (`argocd/apps/kagent-crds.yaml`, `argocd/apps/kagent.yaml`).

### 3. Workflows & Artifacts (Argo Workflows + MinIO)
- **Tool:** [Argo Workflows](https://argoproj.github.io/workflows/) and [MinIO](https://min.io/)
- **Purpose:** Provides a powerful Kubernetes-native workflow engine for orchestrating parallel jobs and CI/CD pipelines. MinIO is installed alongside it to serve as the S3-compatible artifact repository for workflow outputs.
- **Config:** Deployed via ArgoCD (`argocd/apps/argo-workflows.yaml` and `argocd/apps/minio.yaml`).

### 4. Database Management (CloudNativePG)
- **Tool:** [CloudNativePG](https://cloudnative-pg.io/) (CNPG)
- **Purpose:** Used for native PostgreSQL cluster management, offering automated failover, backups, and high availability features inside the cluster.
- **Config:** The operator is deployed via ArgoCD (`argocd/apps/cnpg-operator.yaml`). The declarative databases (Main DB, Kagent DB, Harbor DB) are managed by the `databases` ArgoCD application, which applies the YAMLs from `k8s/databases/`.

### 5. Persistent Storage (NFS)
- **Tool:** NFS Server & NFS CSI Driver
- **Purpose:** Provides ReadWriteMany (RWX) storage capabilities across the cluster, which is essential for certain development workloads and shared data states.
- **Config:** Deploys an in-cluster NFS server (via `raw-manifests`) and the `csi-driver-nfs` controller via ArgoCD (`argocd/apps/nfs.yaml`).

### 6. Development Container (Devcontainer)
- **Tool:** Docker Devcontainer
- **Purpose:** The project contains capability to build a unified development container natively to standardize the local development environment using predefined specifications in a Dockerfile.

## Usage

The cluster setup relies on a single imperative bootstrap step, and then ArgoCD takes over:

### Bootstrapping the Cluster
Run the provided `setup-gitops.sh` script to install ArgoCD and configure the root GitOps application:
```bash
./setup-gitops.sh
```
*(You can optionally pass a Github URL and branch to the script if you are using a different repository fork)*

### Prerequisites
- Docker Desktop with Kubernetes enabled.
- Helm and `kubectl` installed locally.
- `GOOGLE_API_KEY` exported in your environment (for Kagent Gemini provider and ArgoCD secret bootstrapping).
