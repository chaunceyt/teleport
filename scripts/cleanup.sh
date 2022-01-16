#!/bin/bash

# Delete kind cluster
kind delete cluster --name teleport-sandbox

# Bring down dev vault setup
VAULT_PID=$(ps -a | grep "vault server" | head -1 | awk '{print $1}')
kill $VAULT_PID
