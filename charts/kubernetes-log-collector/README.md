# kubernetes-log-collector

A Helm chart for deploying the Red Canary Kubernetes Log Collector

This is a log file forwarder specialized to deal with forwarding Kubernetes audit logs to Red Canary. It is designed to do so reliably and with low overhead while re-shaping the logs (primarily the number of log objects per offloaded file) for effective and timely processing.

## System requirements for the log forwarder
The log forwarder takes very few system resources and requires only read access to the directory the audit logs are being written to and read/write access to a small amount of persistent storage for checkpointing its offload progress.

It is available in 64-bit x86 and arm variants via a multi-arch container.

## Compatibility with Kubernetes
This log forwarder requires access to the control plane nodes where the Kubernetes API server component is running. This rules out running it on managed cluster services such as Amazon EKS, Microsoft AKS, or Google GKE. Those services provide other mechanisms for access to the Kubernetes audit logs.

If your cluster does allow access to the control plane nodes, you must also be able to configure the Kubernetes API server to enable and otherwise configure its audit logging and also make those logs available to a host directory on the node. Exact instructions for doing this unfortunately vary between Kubernetes distributions.

The log forwarder is known to work with the following distributions:
* custom clusters managed with `kubeadm`
* Rancher `k3s`

## Prerequisites
* Helm v3.0.0+
* The container image, tagged and pushed to your private registry
* Credentials for accessing your private registry
* A cluster that allows assigning pods to control plane nodes and configuring of the API audit log service
* Outbound network connectivity on control plane nodes to specific addresses

### Accessing the container images
See the official Red Canary customer documentation for the repository name and access credentials.

### Enabling and configuring Kubernetes API audit logging
The exact methods for enabling and configuring audit logging will vary based on the kubernetes distribution, but there are some general tasks that need to be performed.

**Configuration for `kube-apiserver`**

This component is a core part of kubernetes, and it must be running for the system to work. It therefore cannot be started through the normal scheduling process. It is also configured entirely via command line parameters. Distributions differ in how startup and passing of arguments to it are managed, so the chart cannot provide any automation.

If your cluster shows `kube-apiserver` pods running on control plane nodes, your distribution likely uses [static pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/). You will need to determine whether they are auto-generated and managed by a tool (such as is the case with `kubeadm`) or whether you can safely edit the manifests manually.

Otherwise, the control plane nodes may run `kube-apiserver` as a native service via the distribution's service management tool (`systemd`, etc.) You will need to find and edit or override the service specification to change its configuration.

In the case of `k3s`, the `kube-apiserver` component is built in to the same service binary as other components. The binary still provides a way to pass eqivalents of the command line parameters to the component; see the [`k3s` documentation](https://docs.k3s.io/security/hardening-guide#api-server-audit-configuration) for details.

Regardless of how the service and its configuration are managed, you will need to check the same set of configuration parameters:
1. `audit-policy-file`: Path to the file that defines the audit policy configuration
2. `audit-log-path`: When set, requests to the API server are logged to this fully-qualified file path according to policy

You will need to provide (or possibly edit, if one already exists) a policy file and make sure it is located where the `audit-policy-file` parameter is looking for it. If `kube-apiserver` is deployed via a static pod, you will probably want to provide the file and a log directory to the pod via `volumeMount` parameters.

The chart is not concerned with the policy file, but you will need to note the value you set for `audit-log-path` (along with how that corresponds to any `volumeMount` directory mapping) to set the `directories.log` chart variable (the directory component of the path, mapped to the host filesystem) and the `config.log_file` chart variable (the base name component of the path).

**Audit log policy considerations**

It is unwise to log the full details of every API transaction, so the policy configuration allows you to specify rules by which you can get extra details in some situations and little-to-none in others.

TODO: Describe what details are most relevant, link to example config files

### Outbound network connectivity requirements
* https://o433963.ingest.us.sentry.io
  + 34.120.195.249
* https://cwp-ingest.redcanary.io
  + 3.143.139.141
  + 3.143.177.78
  + 52.14.101.187

Note: cwp-ingest.redcanary.io IPs are static.

To utilize a HTTP proxy, set the following value during your installation:
```console
--set config.http_proxy="https://HOST:PORT"
```
## Installation

### Create a namespace for your installation

```console
kubectl create namespace <NAMESPACE_NAME>
```

### Create a secret to hold your private registry credentials

The image pull secret is used to securely authenticate and authorize container image pulls from your private container registry. *This may not be required in all environments.*

There are two options for doing this.

The first method creates the secret by passing the credential information on the command line. Ensure the namespace parameter matches the one you just created.

```console
kubectl create secret docker-registry <SECRET_NAME> \
  --docker-server=<YOUR_REGISTRY_SERVER> \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_PASSWORD> \
  --docker-email=<YOUR_EMAIL> \
  --namespace=<NAMESPACE_NAME>
```

Alternatively, you can create the secret from the JSON description of a logged-in docker session, such as is typically stored at `~/.docker/config.json` after executing a `docker login` command.

```console
kubectl create secret docker-registry <SECRET_NAME> \
  --from-file=<PATH_TO_JSON_FILE> \
  --namespace=<NAMESPACE_NAME>
```

### Add the Red Canary Helm repository to your system

```console
helm repo add redcanary https://redcanaryco.github.io/helm-charts
helm repo update redcanary
```

### Install the `kubernetes-log-collector` chart

Get the default values file to use as a starting point for configuration.

```console
helm show values redcanary/kubernetes-log-collector > values.yaml
```

Edit the values.yaml file with the following goals in mind:

Ensure the `image` parameters match your private registry and `imagePullSecrets` includes the name of the secret you created with your registry's credentials.

Make sure you set `tolerations` and either `nodeSelector` or `affinity` to ensure the DaemonSet will deploy its pods to the nodes in your control plane that are running `kube-apiserver`.

Set the `directories` parameters to appropriate values so that both `kube-apiserver` and `kubernetes-log-collector` will refer to the same host directory for audit log storage and the collector will have a private persistent state directory.

Set the `config` parameters according to the credentials provided when provisioning the service (`service_id` and `outpost_token`) and ensure `log_file` matches the base name of the active log file that `kube-apiserver` writes audit logs to. Set the `http_proxy` to your proxy URL if you need one for offloading.

```console
helm install klc redcanary/kubernetes-log-collector \
  --namespace=<NAMESPACE_NAME> \
  --values=values.yaml
```

## Removal

Uninstall the DaemonSet with the following command:

```console
helm uninstall klc --namespace<NAMESPACE_NAME>
```

That will stop any running pods, but the namespace and image pull secret will remain until you delete the namespace:

```console
kubectl delete ns <NAMESPACE_NAME>
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | affinity selects nodes for the DaemonSet pods to run on via an affinity specification |
| config.cluster_id | string | `"default_cluster"` | cluster_id is an identifier you choose to distinguish this cluster from others using the same service_id |
| config.http_proxy | string | `nil` | http_proxy is the URL of a HTTP(s) proxy to use, if desired |
| config.log_file | string | `"audit.log"` | log_file is the base file name the apiserver is configured to use for its audit log |
| config.offload_after | string | `"60"` | offload_after is the amount of time, in seconds, to wait between offloads if the desired offload_amount has not yet accumulated |
| config.offload_amount | string | `"50000000"` | offload_amount is the amount of log traffic, in bytes, that should ideally be sent per offload |
| config.outpost_token | string | `nil` | outpost_token is the access token assigned when provisioning the service |
| config.service_id | string | `nil` | service_id is the account identifier assigned when provisioning the service |
| directories.logs | string | `"/var/log/kubernetes"` | logs is the directory in the node's root filesystem where the audit log file can be found |
| directories.state | string | `"/run/kubernetes-log-collector"` | state is the directory in the node's root filesystem to store persistent checkpoint state |
| fullnameOverride | string | `nil` | fullnameOverride is a string to fully override the kubernetes-log-collector.fullname template |
| image.pullPolicy | string | `"IfNotPresent"` | pullPolicy is the policy for fetching images from the repository at runtime |
| image.repository | string | `"redcanary-audit-log-forwarder-prod.jfrog.io/audit-log-forwarder-prod"` | repository is the image repository to pull from <REPLACE_WITH_YOUR_REGISTRY>/audit-log-forwarder-prod |
| image.tag | string | `nil` | tag of the image to deploy. Defaults to the app version of the chart |
| imagePullSecrets | list | `[]` | imagePullSecrets names Secrets that store credentials that are used for accessing the container registry |
| labels | object | `{}` | labels provides extra labels for all the resources created by this chart |
| nameOverride | string | `nil` | nameOverride is a string to partially override the kubernetes-log-collector.fullname template (will maintain the release name) |
| nodeSelector | object | `{}` | nodeSelector selects nodes for the DaemonSet pods to run on by node label |
| podAnnotations | object | `{}` | podAnnotations provides extra annotations for the deployed pod(s) |
| resources | object | `{}` | resources sets the CPU and memory specifications for the pod(s). |
| tolerations | list | `[]` | tolerations allow the DaemonSet pods to run on nodes with specific control plane taints |

----------------------------------------------
<br>

Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs). Any changes to README.md will be overwriten.

To regenerate this document, from the root of this chart directory run:
```shell
docker run --rm --volume "$(pwd):/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.11.0
```
