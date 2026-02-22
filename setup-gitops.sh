#!/bin/bash
set -e -o pipefail

CONTEXT="docker-desktop"
REPO_URL=${1:-"https://github.com/felipefrocha/skaffold-init.git"}
BRANCH=${2:-"main"}

echo "Using Git Repository: $REPO_URL (Branch: $BRANCH)"

if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

if ! kubectl config get-contexts --no-headers 2>/dev/null | awk '{print $2}' | grep -q "^$CONTEXT$"; then
    echo "Context '$CONTEXT' is not present. Please start Docker Desktop and ensure Kubernetes is enabled."
    exit 1
fi

kubectl config use-context "$CONTEXT"

# Install ArgoCD
if ! kubectl get namespace argocd >/dev/null 2>&1; then
    echo "Creating argocd namespace..."
    kubectl create namespace argocd
fi

if helm repo list | grep -q 'argo'; then
    echo "Argo Helm repository already added."
else
    helm repo add argo https://argoproj.github.io/argo-helm
fi

echo "Installing ArgoCD..."
helm upgrade --install argo-cd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --version 6.7.11 \
    -f helm/argo-cd-values.yaml \
    --wait

# Check if GOOGLE_API_KEY is exported
if [ -z "$GOOGLE_API_KEY" ]; then
    echo "⚠️ GOOGLE_API_KEY is not set. The Kagent application will fail to sync correctly."
    echo "   Please export GOOGLE_API_KEY and recreate the secret if needed."
else
    echo "Creating Google API Key secret for Kagent..."
    kubectl create namespace kagent --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic google-api-key -n kagent \
        --from-literal=apiKey="${GOOGLE_API_KEY}" \
        --dry-run=client -o yaml | kubectl apply -f -
fi

echo "Applying bootstrap Application (root-app) — this seeds the two ApplicationSets..."
kubectl apply -f argocd/root-app.yaml

echo 
echo "ArgoCD setup complete. You can access the UI by running:"
echo "kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443"
echo "Username is 'admin', get the password with:"
echo "argocd admin initial-password -n argocd"
