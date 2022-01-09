#!/bin/bash

# Create teleport account within root-cluster namespace.
kubectl exec  deploy/teleport -n root-cluster -- tctl users add tadmin --logins=root --roles=access,editor

# Add teleport account within trusted cluster.
kubectl exec  deploy/teleport -n trusted-cluster-01 -- tctl users add tadmin --logins=root --roles=access,editor


