#!/bin/bash

set -e

# Create cluster
kind create cluster --name teleport-lab --config kind-config.yaml

# Install Minio S3 backend for teleport
kubectl create ns minio
kubectl apply -f manifest/minio.yaml -n minio

# Create root teleport cluster
kubectl create ns root-cluster
kustomize build kustomize/overlays/root-cluster/ | kubectl -n root-cluster apply -f -

kubectl create ns trusted-cluster-01
kustomize build kustomize/overlays/trusted-cluster-01/ | kubectl -n trusted-cluster-01 apply -f -

