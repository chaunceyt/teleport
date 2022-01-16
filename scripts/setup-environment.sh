#!/bin/bash

set -e

# Create cluster
echo "Creating teleport-sandbox kind cluster..."
date
kind create cluster --name teleport-sandbox --config kind-config.yaml

# Install Minio S3 backend for teleport
echo "Installing Minio..."
date
kubectl create ns minio
kubectl apply -f manifest/minio.yaml -n minio

# Create standalone teleport cluster non-HA
echo "Creating the standalone teleport cluster..."
date
kubectl create ns standalone
kustomize build kustomize/base | kubectl -n standalone apply -f -


# Create root teleport cluster
echo "Creating the root teleport cluster..."
date
kubectl create ns root-cluster
kustomize build kustomize/overlays/root-cluster/ | kubectl -n root-cluster apply -f -

echo "Creating the trusted teleport cluster..."
date
kubectl create ns trusted-cluster-01
kustomize build kustomize/overlays/trusted-cluster-01/ | kubectl -n trusted-cluster-01 apply -f -

# Setup Vault environment
echo "Starting vault server..."
date
vault server -dev -dev-root-token-id="root" -dev-listen-address=0.0.0.0:8200 >> /dev/null &
export VAULT_ADDR='http://0.0.0.0:8200'

# Install vault injector
echo "Installing vault-injector..."
LOCAL_IP=$(ipconfig getifaddr en1)
helm install vault hashicorp/vault --set "injector.externalVaultAddr=http://${LOCAL_IP}:8200"

# get vault secret 
VAULT_HELM_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
# kubectl describe secret $VAULT_HELM_SECRET_NAME

# Login 
vault login root

# Enable kubernetes auth
vault auth enable kubernetes

# Setup variables for kubernetes vault config
export TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
export KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')

echo "Writing kubernetes vault config..."
vault write auth/kubernetes/config token_reviewer_jwt="$TOKEN_REVIEW_JWT" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="https://kubernetes.default.svc.cluster.local"

echo "Adding static token to vault path..."
vault kv put secret/teleport/join token="69b56370a584d09d78b25502c1b344c6"

echo "Creating teleport vault policy..."
vault policy write teleport - <<EOF
path "secret/data/teleport/join" {
  capabilities = ["read"]
}
EOF

echo "Creating vault role for standalone-cluster..."
vault write auth/kubernetes/role/standalone-cluster  \
    bound_service_account_names=teleport  \
    bound_service_account_namespaces=root-cluster \
    policies=teleport \
    ttl=24h

echo "Creating vault role for root-cluster..."
vault write auth/kubernetes/role/root-cluster  \
    bound_service_account_names=teleport  \
    bound_service_account_namespaces=root-cluster \
    policies=teleport \
    ttl=24h

echo "Creating vault role for trusted-cluster-01..."
vault write auth/kubernetes/role/trusted-cluster  \
    bound_service_account_names=teleport  \
    bound_service_account_namespaces=trusted-cluster-01 \
    policies=teleport \
    ttl=24h