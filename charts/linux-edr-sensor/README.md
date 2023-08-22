# linux-edr-sensor

A Helm chart for deploying the Red Canary Linux EDR Sensor to Kubernetes

<table><td><h3>Disclaimer: Pre-release Helm Chart</h1>

Please be advised that the Helm chart provided here is currently in a pre-release state and has not yet reached general availability (GA). While we have taken great care to ensure its functionality and reliability, it may still undergo changes and improvements before the final GA version is released.

We encourage you to use this pre-release version for testing and evaluation purposes. However, it is not recommended for production environments or critical workloads at this stage. Keep in mind that features, configuration options, and other aspects of the chart may evolve before the GA release.

Your feedback and insights are invaluable to us as we work towards refining and enhancing the Helm chart. Feel free to report any issues, suggestions, or observations you encounter during your testing. We greatly appreciate your understanding and support as we strive to deliver a robust and feature-rich chart for your use.

Thank you for your interest in our project and for participating in its development journey.

Sincerely,<br>
The Red Canary Team
</td></table><br>

Our unique lightweight agent was designed to silently collect telemetry data while minimizing any possible performance impact. Red Canary [Linux EDR](https://redcanary.com/products/linux-edr/) and MDR extends Managed Detection and Response to your entire on-prem and cloud Linux infrastructure with deep Linux threat detection expertise and experience.

## System requirements for the Linux EDR sensor
For the most up to date requirements, please visit [help.redcanary.com](https://help.redcanary.com/hc/en-us/articles/360052515594-System-requirements-for-Linux-EDR).

## Compatibility with Kubernetes
The linux-edr-sensor chart has undergone testing for deployment on these Kubernetes distributions:
* Rancher k3s & k3d
* Amazon EKS
* Azure AKS

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

```console
kubectl create secret docker-registry <SECRET_NAME> \
  --docker-server=<YOUR_REGISTRY_SERVER> \
  --docker-username=<YOUR_USERNAME> \
  --docker-password=<YOUR_PASSWORD> \
  --docker-email=<YOUR_EMAIL> \
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
```console
helm install linux-edr-sensor redcanary/linux-edr-sensor \
--version <VERSION_FROM_ABOVE> \
--namespace=<NAMESPACE_FROM_ABOVE> \
--set config.accessToken=<YOUR_ACCESS_TOKEN> \
--set config.outpostAuthToken=<YOUR_OUTPOST_TOKEN> \
--set image.repository=<YOUR_REGISTRY_SERVER> \
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
| persistence.enabled | bool | `true` | Whether or not persistent storage should be used for the sensor's /tmp and /logs data. |
| persistence.logDir | string | `"/var/log"` | The path on the host to use for persistent log storage. Only used when type is set to 'hostpath'. |
| persistence.tmpDir | string | `"/tmp"` | The path on the host to use for persistent tmp storage. Only used when type is set to 'hostpath'. |
| podAnnotations | object | `{}` | Additional annotations for the deployed pod(s). |
| resources | object | `{}` | Sets the allocated CPU and memory specifications for the pod(s). |
| tolerations | list | `[]` | Tolerations allow the pod to be scheduled onto nodes with specific taints. Examples can be used if needed to tolerate all taints, or for well-known control-plane taints. |

----------------------------------------------
<br>
Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs). Any changes to README.md will be overwriten.

To regenerate this document, from the root of this chart directory run:
```shell
docker run --rm --volume "$(pwd):/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.11.0
```