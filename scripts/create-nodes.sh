#!/bin/bash

DEFAULT_JOIN_TOKEN=69b56370a584d09d78b25502c1b344c6

# Create join token for standalone-cluster
STANDALONE_CLUSTER_TOKEN=$(kubectl exec  deploy/teleport -n standalone -- tctl nodes add --ttl=48h --roles=node --token=${DEFAULT_JOIN_TOKEN})
STANDALONE_CLUSTER_IP=$(echo $STANDALONE_CLUSTER_TOKEN | awk '{print $32}' | cut -d"=" -f2 | cut -d":" -f1)

echo "Trusted cluster IP: ${STANDALONE_CLUSTER_IP}"
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set sshNodeName=webapp --set authServer=${STANDALONE_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n standalone apply -f -

# Create join token for root-cluster
ROOT_CLUSTER_TOKEN=$(kubectl exec  deploy/teleport -n root-cluster -- tctl nodes add --ttl=48h --roles=node --token=${DEFAULT_JOIN_TOKEN})
ROOT_CLUSTER_IP=$(echo $ROOT_CLUSTER_TOKEN | awk '{print $32}' | cut -d"=" -f2 | cut -d":" -f1)

echo "Root cluster IP: ${ROOT_CLUSTER_IP}"
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=2 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=dev,labels.role=webapp --set sshNodeName=webapp --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=dev,labels.role=database --set sshNodeName=database --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=dev,labels.role=cache --set sshNodeName=cache --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=2 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=stage,labels.role=webapp --set sshNodeName=webapp --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=stage,labels.role=database --set sshNodeName=database --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.account=ffbd-dev,labels.team=team-c,labels.env=stage,labels.role=cache --set sshNodeName=cache --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=5 --set labels.account=fbda-live,labels.team=team-dba,labels.env=stage,labels.role=database --set sshNodeName=mongodb --set authServer=${ROOT_CLUSTER_IP} helm/teleport-nodes/ | kubectl -n root-cluster apply -f -

# Create join token for trusted-cluster
TRUSTED_CLUSTER_01_TOKEN=$(kubectl exec  deploy/teleport -n trusted-cluster-01 -- tctl nodes add --ttl=48h --roles=node --token=${DEFAULT_JOIN_TOKEN})
TRUSTED_CLUSTER_01_IP=$(echo $TRUSTED_CLUSTER_01_TOKEN | awk '{print $32}' | cut -d"=" -f2 | cut -d":" -f1)

echo "Trusted cluster IP: ${TRUSTED_CLUSTER_01_IP}"
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.team=team-a,labels.env=dev,labels.role=database --set sshNodeName=database-deva --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.team=team-b,labels.env=dev,labels.role=database --set sshNodeName=database-devb --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.team=team-b,labels.env=stage,labels.role=database --set sshNodeName=database-stage --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=1 --set labels.team=team-b,labels.env=dev,labels.role=cache --set sshNodeName=cache-dev --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=2 --set labels.account=dead-live,labels.team=team-dba,labels.env=live,labels.role=database --set sshNodeName=mongodb-ops --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
helm template ssh-node --set joinToken=${DEFAULT_JOIN_TOKEN} --set replicaCount=3 --set labels.account=dead-live,labels.team=team-dba,labels.env=live,labels.role=database --set sshNodeName=mongodb-web --set authServer=${TRUSTED_CLUSTER_01_IP} helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -
