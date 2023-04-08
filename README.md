# argocd-renovate

Using Renovate to update ArgoCD Applications automatically.

Example PR: https://github.com/seanturner026/argocd-renovate/pull/1

```bash
# Create k8s cluster with Kind.
kind create cluster --name local

# Install ArgoCD.
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Configure Renovate pre-resources. Requires $GITHUB_TOKEN in environment
envsubst < secret.yaml > .tmp/secret.yaml
kubectl create namespace renovate
kubectl apply -f .tmp/secret.yaml

kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode

kubectl port-forward svc/argocd-server -n argocd 8080:443
```
