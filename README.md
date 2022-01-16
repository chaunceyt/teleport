# Teleport Sandbox (DRAFT)

Being responsible for implementing Teleport as a solution to replace the usage of bastion hosts, when needing to connect to internal servers via openssh. I needed an environment to teach myself how to operate Teleport. As a result, I created a "Teleport Sandbox" using:

- Kubernetes cluster using `kind`
- Etcd used as the backend for Teleport.
- Minio for S3 compatible storage
- Vault used to store the static join token for nodes
- Vault injector used to inject the vault secret into the pod
- Kustomize is being used to create a standalone, root-cluster, and trusted-cluster Teleport environment
- Kubernetes Statefulsets are used as nodes

The operational tasks that can be performed in the sandbox

- Creating teleport users and roles
- Create trust between teleport clusters
- Using terraform to manage users and roles
- Inspect how data is stored in Etcd
- Use client (`tsh`) and administration (`tctl`) tools to interact with Teleport
- Understand Teleport's RBAC label matching

## Create sandbox environment

- Install `kind` [binary](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) 
- Install `kustomize` [binary](https://github.com/kubernetes-sigs/kustomize)
- Install `vault` binary
- Install `helm` binary
- Install `kubectl` binary

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

git clone https://github.com/chaunceyt/teleport.git telelport-sandbox
cd telelport-sandbox
make sandbox
```

### Trusted cluster setup
> The design of trusted clusters allows Teleport users to connect to compute infrastructure located behind firewalls without any open TCP ports

- [Docs](https://goteleport.com/docs/setup/admin/trustedclusters/)
- [Joind tokens](https://goteleport.com/docs/setup/admin/trustedclusters/#join-tokens)
- `make setup-trusted-cluster`

### Adding SSH nodes

- [The Node service](https://goteleport.com/docs/architecture/nodes/)
- [static tokens](https://goteleport.com/docs/setup/admin/adding-nodes/#insecure-static-tokens)
- [EC2 method](https://goteleport.com/docs/setup/guides/joining-nodes-aws/)

- Run `make create-nodes`

### Connect to teleport clusters

- Run `make port-forward`
- open https://localhost:50443
- open https://localhost:60443


### Use the teleport-client pod to interact with environment

```
kubectl exec -it teleport-client -- bash
```

### Review the UI for for each of the binaries: `tsh`, `tctl`, and `teleport`

```
# Log into the root cluster
tsh login --proxy=teleport.root-cluster.svc.cluster.local:443 --insecure --user tadmin --auth=local

# list nodes available
tsh ls

# list clusters
tsh clusters

# list nodes available on another cluster
tsh ls --cluster=[clusterName]

# Connect to node on another cluster
tsh ssh --cluster=[clusterName] root@ssh-node-0
```

### Terraform provider setup in teleport client 
```
mkdir -p ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
curl -L -O https://get.gravitational.com/terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz
tar -zxvf terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz -C ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
```

# Notes

## What is Teleport?

- [Architecture Introduction](https://goteleport.com/docs/architecture/overview/)
- [Example setups](https://github.com/gravitational/teleport/tree/master/examples)

## Managing teleport
- [Scaling](https://goteleport.com/docs/setup/operations/scaling/)
- [Cert Authority Rotation](https://goteleport.com/docs/setup/operationsca-rotation/)
- [Joining Node and Proxies in AWS](https://goteleport.com/docs/setup/guides/joining-nodes-aws/)
- [TLS Routing](https://goteleport.com/docs/architecture/tls-routing/)
- Understand [how RBAC label matching works](https://github.com/gravitational/teleport/discussions/8766)

## Teleport Backends for High Availability

- [DynamoDB](https://goteleport.com/docs/setup/reference/backends/#dynamodb)
- [Etcd](https://goteleport.com/docs/setup/reference/backends/#etcd)
- S3


## Trusted cluster(s)

> trusted clusters allows Teleport users to connect to compute infrastructure located behind firewalls without any open TCP ports

- [Teleport docs](https://goteleport.com/docs/setup/admin/trustedclusters/)

## ETCD backend review and management

```
kubectl exec -it sts/etcd -n root-cluster -- bash
apt update
apt install curl
curl -Lo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x /usr/local/bin/jq

ETCDCTL_API=3

# Get list of keys available
etcdctl get / --keys-only --prefix

# Review the contents of a key
etcdctl get /teleport.secrets//authservers/c548dd43-f751-4f65-ae4e-9de7b0a785b8 --print-value-only | base64 -d  | jq .

# List nodes
etcdctl get --prefix /teleport.secrets//nodes --keys-only

# Perform a backup of state
etcdctl snapshot save snapshotdb-$(date +%m-%d-%y)
etcdctl snapshot status snapshotdb-$(date +%m-%d-%y) --write-out=table

# Run some checks against the system
etcdctl check datascale # Check the memory usage of holding data for different workloads on a given server endpoint.
etcdctl check perf # Check the performance of the etcd cluster

```