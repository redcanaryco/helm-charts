# linux-edr-sensor

A Helm chart for deploying the Red Canary Linux EDR Sensor to Kubernetes

Our unique lightweight agent was designed to silently collect telemetry data while minimizing any possible performance impact. Red Canary [Linux EDR](https://redcanary.com/products/linux-edr/) and MDR extends Managed Detection and Response to your entire on-prem and cloud Linux infrastructure with deep Linux threat detection expertise and experience.

## System requirements for the Linux EDR sensor
For the most up to date requirements, please visit [help.redcanary.com](https://help.redcanary.com/hc/en-us/articles/360052515594-System-requirements-for-Linux-EDR).

## Compatibility with Kubernetes
The linux-edr-sensor chart has undergone testing for deployment on these Kubernetes distributions:
* Rancher k3s & k3d
* Amazon EKS
* Azure AKS
* Google GKE (see extra configuration requirements below)
* OpenShift (see special instructions below)

## Multi-architecture kubernetes clusters
The current state of the Canary Forwarder Docker image does not support multi-architecture builds. In the context of a multi-architecture Kubernetes cluster (including both arm64 and amd64 nodes), deploying two daemonsets becomes necessary. Each daemonset should reference the respective image and incorporate the required affinities to accommodate this architecture diversity.

## Prerequisites
* Helm v3.0.0+
* The canary-forwarder image, tagged and pushed to your private registry
* Credentials for accessing your private registry
* Outbound network connectivity

### Accessing the canary-forwarder image
[Where Do I Get the Linux EDR Docker Container Image?](https://help.redcanary.com/hc/en-us/articles/1500007392202-Where-Do-I-Get-the-CWP-Docker-Container-Image-)

### Outbound network connectivity
* s3-us-east-2.amazonaws.com (tcp/443)
* 35.188.42.15 (tcp/443)
* 34.120.195.249 (tcp/443)
* https://cwp-ingest.redcanary.io

Note: cwp-ingest.redcanary.io IPs are static.

To utilize a HTTP proxy, set the following value during your installation:
```console
--set config.extraOptions.http_proxy="https://HOST:PORT"
```

## Installation

### Create a namespace for your installation
Creating a dedicated namespace for a specific deployment within Kubernetes is considered a best practice due to its distinct advantages in terms of organization, resource management, and security. This approach prevents potential naming conflicts, enhances resource allocation, and enables more precise access controls, contributing to a streamlined and secure operational environment.

```console
kubectl create namespace <NAMESPACE_NAME>
```

### Configure Pod Security Standards with Namespace labels
[Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) became generally available in Kubernetes v1.25 onwards. [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) define policies used to secure pods and can be configured by [adding labels](https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/) to your namespaces.

```console
kubectl label --overwrite ns <NAMESPACE_NAME> pod-security.kubernetes.io/enforce=privileged
```

### Create a secret to hold your private registry credentials
The image pull secret is used to securely authenticate and authorize container image pulls from your private container registry. *This may not be required in all environments*

For the `docker-server` parameter, use the base URL for the registry server. For example, if it is hosted at `docker.mydomain.com` use `--docker-server="https://docker.mydomain.com"`

```console
kubectl create secret docker-registry <SECRET_NAME> \
  --docker-server=<YOUR_REGISTRY_SERVER_URL> \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_PASSWORD> \
  --namespace=<NAMESPACE_FROM_ABOVE>
  ```

### Add the Red Canary Helm repository to your system
```console
helm repo add redcanary https://redcanaryco.github.io/helm-charts
helm repo update redcanary
```

### Viewing available chart and sensor versions
Use the following command to determine which chart version you need to install based on the desired sensor version.
```console
helm search repo redcanary/linux-edr-sensor --versions
```

### Install the Helm chart
For the `image.repository` parameter, you need to specify the container image as you would to docker. For example, if your registry is at `docker.mydomain.com` and you kept the image name as `canary_forwarder`, you would use `--set image.repository="docker.mydomain.com/canary_forwarder"`.

It is a best practice to use specific image tags rather than floating tags like `latest`, so be sure to specify the specific latest version in the `image.tag` parameter. For example, `--set image.tag=1.10.2-25540`.

```console
helm install linux-edr-sensor redcanary/linux-edr-sensor \
--version <VERSION_FROM_ABOVE> \
--namespace=<NAMESPACE_FROM_ABOVE> \
--set config.accessToken=<YOUR_ACCESS_TOKEN> \
--set config.outpostAuthToken=<YOUR_OUTPOST_TOKEN> \
--set image.repository=<YOUR_REPOSITORY_NAME>/<IMAGE_NAME> \
--set image.tag=<DESIRED TAG> \
--set imagePullSecrets[0].name=<SECRET_NAME_FROM_ABOVE>  # Omit if not using an image pull secret
```

## Helpful commands for interacting with your pods
To see the names of your running pods:
```console
kubectl get pods -n <NAMESPACE_FROM_ABOVE>
```

Once you have the names of your pods, you can tail their logs:
```console
kubectl logs -f <POD_NAME> -n <NAMESPACE_FROM_ABOVE>
```

Or use an interactive shell to access the running pod
```console
kubectl exec --stdin --tty <POD_NAME> -n <NAMESPACE_FROM_ABOVE> -- /bin/sh
```

## Removal

### Remove the linux-edr-sensor release from your kubernetes cluster

```console
helm uninstall linux-edr-sensor
```

Uninstalling the helm chart will not remove the namespace or image pull secret. This will clean up the remaining kubernetes resources.

```console
kubectl delete ns <YOUR_NAMESPACE>
```

## Google Kubernetes Engine Configuration

When installing the sensor in a Google Cloud environment using Google's Container Optimized OS, you must ensure that the persistent directory for node state is placed in a different location than default, because the default location is mounted with the `noexec` flag.

An option to `helm install` that has been tested to work is the following:

```console
--set persistence.nodestateDir=/var/lib/toolbox/redcanary
```

## OpenShift Install

Installing on OpenShift requires some additional steps before the instructions listed above, as well as some small modifications to them.

1. Create and configure the project and a service account for it
    ```console
    oc new-project linux-edr-sensor
    ```

    ```console
    oc create sa linux-edr-sensor
    ```

    OpenShift project creation also creates a namespace of the same name, so keep that in mind for `helm` and `kubectl` commands that take namespace arguments.

2. Configure policy for the new service account
    ```console
    oc adm policy add-scc-to-user privileged -z linux-edr-sensor
    ```

    This adds the `privileged` Security Context Contstraint to the service account's constraints. This allows pods that specify this service acount to run effectively without security constraints. This is necessary because the sensor needs full access to all of the host resources to properly monitor all the other activity on the node.

3. Follow normal install instructions with some minor changes
    Skip the first step of namespace creation, since one was already created with the project.

    Follow the rest of the steps until the final one, using `linux-edr-sensor` as the namespace name.

    For the final `helm install` command, you will need to add two extra `--set` flags to ensure the chart installs the pods with the correct service account association:

    ```console
    --set useServiceAccount=true \
    --set serviceAccountName=linux-edr-sensor \
    ```

    OpenShift clusters (aside from single-node development clusters) also have control plane nodes tainted by default, so a toleration will need to be added to allow monitoring control plane nodes:

    ```console
    --set tolerations[0].key="node-role.kubernetes.io/master"
    --set tolerations[0].effect=NoSchedule
    ```

    You may want to use the `--dry-run` parameter to `helm` on your first attempt in order to look at the resulting resources, to make sure the `serviceAccountName` and `tolerations` are set as you expected in the pod spec.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Use this to define a custom affinity section, using standard k8s syntax. |
| config | object | `{"accessToken":null,"extraOptions":null,"outpostAuthToken":null,"reportingTags":null,"telemetrySource":"ebpf"}` | Values used for the default configuration. These will not be used if overrideConfig is set to true. |
| config.accessToken | string | `nil` | Required. Parameter for configuring access token. |
| config.extraOptions | string | `nil` | Additional configuration options to be passed to the Red Canary Linux EDR Sensor. Please only use when troubleshooting with Red Canary. |
| config.outpostAuthToken | string | `nil` | Required. Parameter for configuring Outpost auth. |
| config.reportingTags | string | `nil` | Optional. This becomes the value of the "endpoint_reporting_tags" field included in the envelope fields of all telemetry/health files that are offloaded. |
| config.telemetrySource | string | `"ebpf"` | Optional. Only required for endpoints where we wish to use the eBPF telemetry collection method. |
| fullnameOverride | string | `""` | String to fully override linux-edr-sensor.fullname template |
| image.pullPolicy | string | `"IfNotPresent"` | The policy for fetching images from the repository at runtime. |
| image.repository | string | `"redcanary-forwarder-docker-prod-local.jfrog.io/canary_forwarder"` | The image repository to pull from<br> <REPLACE_WITH_YOUR_REGISTRY>/canary_forwarder |
| image.tag | string | `nil` | Tag of the image to deploy. Defaults to the app version of the chart. |
| imagePullSecrets | list | `[]` | Secret that stores credentials that are used for accessing the container registry |
| labels | object | `{}` | Additional labels to add to all the resources created by this chart. |
| nameOverride | string | `""` | String to partially override linux-edr-sensor.fullname template (will maintain the release name) |
| nodeSelector | object | `{}` | When you specify a nodeSelector, the Kubernetes scheduler will only consider nodes that match the labels you have specified. nodeAffinity is preferred see k8s documentations for further detail - https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| persistence.enabled | bool | `true` | Whether or not persistent storage should be used for the sensor's /var, /tmp and /logs data. |
| persistence.logDir | string | `"/var/log"` | The path on the host to use for persistent log storage. Only used when enabled is set to true. |
| persistence.nodestateDir | string | `"/var/lib/misc/redcanary"` | The path on the host to use for persistent node state. You must ensure this is not on a mount with the 'noexec' flag. Only used when enabled is set to true. |
| persistence.tmpDir | string | `"/tmp"` | The path on the host to use for persistent tmp storage. Only used when enabled is set to true. |
| podAnnotations | object | `{}` | Additional annotations for the deployed pod(s). |
| resources | object | `{}` | Sets the allocated CPU and memory specifications for the pod(s). |
| serviceAccountName | string | `""` | If a ServiceAccount is being used, this names it |
| tolerations | list | `[]` | Tolerations allow the pod to be scheduled onto nodes with specific taints. Examples can be used if needed to tolerate all taints, or for well-known control-plane taints. |
| useServiceAccount | bool | `false` | Whether or not the DaemonSet's pod should be associated with a ServiceAccount |

----------------------------------------------
<br>
Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs). Any changes to README.md will be overwriten.

To regenerate this document, from the root of this chart directory run:
```shell
docker run --rm --volume "$(pwd):/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.11.0
```
