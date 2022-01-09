#!/bin/bash

# Create join token for root-cluster
kubectl exec  deploy/teleport -n root-cluster -- tctl nodes add --ttl=48h --roles=node

# Craete join token for trusted-cluster
kubectl exec  deploy/teleport -n trusted-cluster-01 -- tctl nodes add --ttl=48h --roles=node

