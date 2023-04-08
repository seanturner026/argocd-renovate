#!/bin/bash

set -x
set -o errexit
set -o pipefail
set -o nounset

# Create k8s cluster with Kind.
kind create cluster --name local --config kind.yaml

# Install ArgoCD.
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p \
'{
    "spec": {
        "type": "NodePort",
        "ports": [
            {
                "name": "http",
                "nodePort": 30080,
                "port": 80,
                "protocol": "TCP",
                "targetPort": 8080
            }, {
                "name": "https",
                "nodePort": 30443,
                "port": 443,
                "protocol": "TCP",
                "targetPort": 8080
            }
        ]
    }
}'

set +o errexit
set +o pipefail

for i in {1..10}; do
    PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode)
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 1
done

set -o errexit
set -o pipefail

argocd login localhost:8080 --username admin --password $PASSWORD --insecure
argocd cluster add kind-local --yes

mkdir -p .tmp
envsubst < applications/renovate/secret.yaml > .tmp/secret.yaml

# Configure Renovate pre-resources.
kubectl create namespace renovate
kubectl apply -f .tmp/secret.yaml

# Create ArgoCD Applications.
argocd app create cluster-applications \
    --repo https://github.com/seanturner026/argocd-renovate.git \
    --path applications \
    --dest-namespace argocd \
    --dest-server https://kubernetes.default.svc
