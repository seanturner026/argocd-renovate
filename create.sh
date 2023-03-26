# Create k8s cluster with Kind.
kind create cluster --name local

# Install ArgoCD.
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443

PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)
argocd login localhost:8080 --username admin --password $PASSWORD
argocd cluster add kind-local --yes

# Configure Renovate pre-resources.
kubectl create namespace renovate
kubectl apply -f applications/renovate/secret.yaml
kubectl edit secret renovate -n renovate

# Create ArgoCD Applications.
argocd app create cluster-applications \
    --repo https://github.com/seanturner026/argocd-renovate.git \
    --path applications \
    --dest-namespace default \
    --dest-server https://kubernetes.default.svc
