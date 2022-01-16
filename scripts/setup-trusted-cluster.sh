#!/bin/bash

NAMESPACE=trusted-cluster-01

POD=$(kubectl get po -o name -n ${NAMESPACE} -l app=teleport | head -1 | cut -d"/" -f2)
kubectl cp teleport-trusted-cluster.yaml -n ${NAMESPACE} ${POD}:/tmp
kubectl exec ${POD} -n ${NAMESPACE} -- tctl create -f /tmp/teleport-trusted-cluster.yaml

NAMESPACE=standalone
POD=$(kubectl get po -o name -n ${NAMESPACE} -l app=teleport | head -1 | cut -d"/" -f2)
kubectl cp standalone-trusted-cluster.yaml -n ${NAMESPACE} ${POD}:/tmp
kubectl exec ${POD} -n ${NAMESPACE} -- tctl create -f /tmp/standalone-trusted-cluster.yaml
