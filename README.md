# Teleport Sandbox (DRAFT)

Being responsible for implementing Teleport as a solution to replace the usage of bastion hosts, when needing to connect to internal servers via openssh. I needed an environment to teach myself how to operate Teleport. As a result, I created a "Teleport Sandbox" using:

- Kubernetes cluster using `kind`
- Three Teleport clusters
- Etcd used as the backend for two of the Teleport clusters.
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
### Connect to teleport clusters

Append the following to your /etc/hosts `127.0.0.1` entry.
i.e. 

```
127.0.0.1       localhost teleport.teleport.svc.cluster.local teleport.trusted-cluster-01.svc.cluster.local teleport.root-cluster.svc.cluster.local teleport.standalone.svc.cluster.local
```

- Run `make port-forward`
- open https://teleport.standalone.svc.cluster.local:40443
- open https://teleport.root-cluster.svc.cluster.local:50443
- open https://teleport.trusted-cluster-01.svc.cluster.local:60443

### Create admin accounts

- Run `make teleport-admins` and for each domain fix the port from `443` --> `XX443` and set a password for the `tadmin` account.
- Login and nagivate around each environment. At the moment neither has nodes that allows one to connect and login. Also for each cluster there is only one cluster listed in the `CLUSTER:` dropdown. That specific cluster's name'.

### Trusted cluster Setup
> The design of trusted clusters allows Teleport users to connect to compute infrastructure located behind firewalls without any open TCP ports

- [Docs](https://goteleport.com/docs/setup/admin/trustedclusters/)
- [Joind tokens](https://goteleport.com/docs/setup/admin/trustedclusters/#join-tokens)

The sandbox configures the `standalone` and `trusted-cluster-01` to trust the `root-cluster` Teleport cluster.

- Review `teleport-trusted-cluster.yaml` and `standalone-trusted-cluster.yaml` then run `make setup-trusted-cluster`
- Login and navigate around each environment. Under `CLUSTER:` for the root-cluster there should be two additional clusters. Each of the other clusters only list that specific cluster's name.

### Adding SSH nodes

- [The Node service](https://goteleport.com/docs/architecture/nodes/)
- [static tokens](https://goteleport.com/docs/setup/admin/adding-nodes/#insecure-static-tokens)
- [EC2 method](https://goteleport.com/docs/setup/guides/joining-nodes-aws/)

The sandbox uses static tokens to add nodes to the teleport clusters. A number of nodes are created with various labels that will help us understand the use of labels for RBAC 

- Run `make create-nodes` to create some nodes in each teleport cluster created in the sandbox.
- Login to each cluster and there should be a number of nodes listed under `Servers`


### Use the teleport-client pod to interact with environment

```
kubectl -n root-cluster exec -it teleport-client -- bash
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

# Repeat the above commands on the other clusters. Note if trusted clusters were setup, the root-cluster has a list of clusters and the other cluster don't at the moment.

# Proxy addresses for each cluster

- `root-cluster` = teleport.root-cluster.svc.cluster.local:443
- `standalone` = teleport.standalone.svc.cluster.local:443
- `trusted-cluster-01` = teleport.trusted-cluster-01.svc.cluster.local:443


```
### Terraform provider setup in teleport client 
```
kubectl -n root-cluster exec -it teleport-client -- bash
apt update
apt install -y curl vim unzip git dnsutils netcat 
mkdir -p ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
curl -L -O https://get.gravitational.com/terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz
tar -zxvf terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz -C ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
mkdir terraform-teleport && cd terraform-teleport
curl -L -o main.tf https://raw.githubusercontent.com/gravitational/teleport/master/examples/resources/terraform/terraform-user-role.tf

# Update the addr value.
addr               = "teleport-management.root-cluster.svc.cluster.local:3025"

# Create Identify file
tsh login --proxy=teleport.root-cluster.svc.cluster.local:443 --user tadmin --insecure
tctl auth sign --format=file --user=terraform --out=terraform-identity --ttl=10h --insecure

terraform init
terraform plan
terraform apply

```

### Add Database: standalone Mysql

```
# connect to standalone teleport cluster
tsh login --proxy=teleport.standalone.svc.cluster.local:443 --user tadmin --insecure
mkdir /tmp/server
cd /tmp/server
tctl --insecure auth sign --proxy=teleport.root-cluster.svc.cluster.local:443 --format=db --host=teleport-db-mysql.dev.svc.cluster.local --out=server --ttl=2190h
cd /tmp
tar -czf teleport-certs.tar.gz server/
exit
kubectl cp [podname]:/tmp/teleport-certs.tar.gz ./teleport-certs.tar.gz
tar -xvzv teleport-certs.tar.gz 
cd server
kubectl create cm teleport-mysql-certs --from-file=server.cas --from-file=server.crt --from-file=server.key --dry-run=client -o yaml > ../mysql-teleport-certs.yaml
cd ../
kubectl create ns dev
kubectl apply -n dev -f mysql-teleport-certs.yaml
kubectl apply -n dev -f mysql-deployment.yaml

# connect to database
kubectl get po -n dev
kubectl exec -it [podname] -n dev -- bash
mysql mysql -uroot -prootpassword

CREATE USER 'tadmin'@'%' REQUIRE SUBJECT '/CN=tadmin';
GRANT ALL ON *.* TO 'tadmin'@'%';
FLUSH PRIVILEGES;

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

- [maintenance](https://etcd.io/docs/v3.2/op-guide/maintenance/)

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