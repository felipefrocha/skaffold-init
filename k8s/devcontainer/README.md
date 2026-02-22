# Devcontainer on Kind (local cluster)

Run the devcontainer as a Pod in a local Kind cluster with a hostPath volume so the container sees your local project directory.

## 1. Kind cluster with host path

Create the Kind cluster with `extraMounts` so the node has your project dir at `/workspace`:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /path/to/devex          # your project dir on the host
    containerPath: /workspace         # path on the node (used by pod hostPath)
```

```bash
kind create cluster --config kind-config.yaml
```

## 2. Build and load the devcontainer image

From the project root:

```bash
docker build --target devcontainer -t devex-devcontainer:latest .
kind load docker-image devex-devcontainer:latest
```

## 3. Deploy the pod and service

```bash
kubectl apply -f k8s/devcontainer/devcontainer.yaml
```

## 4. Use the devcontainer

- **Shell:** `kubectl exec -it devcontainer -- /bin/zsh`
- **Port-forward (e.g. app on 8000):** `kubectl port-forward pod/devcontainer 8000:8000`

The container’s `/workspace` is the hostPath; it will match your local folder if Kind was created with the `extraMounts` above.
