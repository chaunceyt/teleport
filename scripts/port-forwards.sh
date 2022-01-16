#!/bin/bash

# Create port-forward for minio
kubectl port-forward svc/minio -n minio 9000:9000 >> /dev/null &
kubectl port-forward svc/minio-console -n minio 9001:9001 >> /dev/null &

# Create port-forward to standalone cluster
kubectl -n standalone port-forward svc/teleport 40443:443 >> /dev/null &

# Create port-forward to root-cluster
kubectl -n root-cluster port-forward svc/teleport 50443:443 >> /dev/null &

# Create port-forward to trusted cluster
kubectl -n trusted-cluster-01 port-forward svc/teleport 60443:443 >> /dev/null &
