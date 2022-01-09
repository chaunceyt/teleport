# teleport

## What is Teleport

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

## Teleport Lab

This lab creates two teleport clusters with Etcd as the state backend and Minio for S3 bucket for session recordings.

After setting up the infrastructure for the lab. We will
- create users and roles using tctl and terraform
- establish trust between the two teleport clusters created for this lab
- review the data stored in Etcd

### Create environment

- Install `kind` [binary](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) 
- Install `kustomize` [binary](https://github.com/kubernetes-sigs/kustomize)
- Create cluster `make lab`

Trusted cluster setup
> The design of trusted clusters allows Teleport users to connect to compute infrastructure located behind firewalls without any open TCP ports

- [Docs](https://goteleport.com/docs/setup/admin/trustedclusters/)
- [Joind tokens](https://goteleport.com/docs/setup/admin/trustedclusters/#join-tokens)
- `make setup-trusted-cluster`

Adding SSH nodes

- [The Node service](https://goteleport.com/docs/architecture/nodes/)
- [static tokens](https://goteleport.com/docs/setup/admin/adding-nodes/#insecure-static-tokens)
- [EC2 method](https://goteleport.com/docs/setup/guides/joining-nodes-aws/)

Join tokens

- Run `make generate-join-tokens`
- Run `helm template ssh-node --set joinToken=[joinToken] --set authServer=[authServer] helm/teleport-nodes/ | kubectl -n root-cluster apply -f -`
- Run `helm template ssh-node --set joinToken=[joinToken] --set authServer=[authServer] helm/teleport-nodes/ | kubectl -n trusted-cluster-01 apply -f -`

Connect to teleport clusters

- Run `make port-forward`
- open https://localhost:50443
- open https://localhost:60443


Use the teleport-client pod to interact with environment

```
kubectl exec -it teleport-client -- bash
```

Review the UI for for each of the binaries: `tsh`, `tctl`, and `teleport`

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

Terraform provider setup
```
mkdir -p ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
curl -L -O https://get.gravitational.com/terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz
tar -zxvf terraform-provider-teleport-v8.0.7-linux-amd64-bin.tar.gz -C ${HOME?}/.terraform.d/plugins/gravitational.com/teleport/teleport/8.0.7/linux_amd64
```
