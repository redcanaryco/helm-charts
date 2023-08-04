# linux-edr-sensor

A Helm chart for deploying the Red Canary Linux EDR Sensor to Kubernetes

This chart will not install without certain values being set. Please refer to [Installation](#installation) for details.

Our unique lightweight agent was designed to silently collect telemetry data while minimizing any possible performance impact. Red Canary [Linux EDR](https://redcanary.com/products/linux-edr/) and MDR extends Managed Detection and Response to your entire on-prem and cloud Linux infrastructure with deep Linux threat detection expertise and experience.

## Installation

To install this helm chart, simply add the redcanary helm repo and install the chart with the required values provided by Red Canary. Note that we do not set a default version for the image tag, leaving this as a concious decision for the user.

```console
helm repo add redcanary https://redcanaryco.github.io/helm-charts
helm install linux-edr-sensor redcanary/linux-edr-sensor \
--set config.accessToken=<YOUR_ACCESS_TOKEN> \
--set config.outpostAuthToken=<YOUR_OUTPOST_TOKEN> \
--set image.tag=<DESIRED TAG>
```

## Removal

```console
helm uninstall linux-edr-sensor
```

## Prerequisites

* Helm v3.0.0+

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config | object | `{"accessToken":null,"extraOptions":null,"outpostAuthToken":null,"reportingTags":null,"telemetrySource":"ebpf"}` | Values used for the default configuration. These will not be used if overrideConfig is set to true. |
| config.accessToken | string | `nil` | Required. Parameter for configuring access token. |
| config.extraOptions | string | `nil` | Additional configuration options to be passed to the Red Canary Linux EDR Sensor. Please only use when troubleshooting with Red Canary. |
| config.outpostAuthToken | string | `nil` | Required. Parameter for configuring Outpost auth. |
| config.reportingTags | string | `nil` | Optional. This becomes the value of the "endpoint_reporting_tags" field included in the envelope fields of all telemetry/health files that are offloaded. |
| config.telemetrySource | string | `"ebpf"` | Optional. Only required for endpoints where we wish to use the eBPF telemetry collection method. |
| fullnameOverride | string | `""` | String to fully override linux-edr-sensor.fullname template |
| image.pullPolicy | string | `"IfNotPresent"` | The policy for fetching images from the repository at runtime. |
| image.repository | string | `"redcanary-forwarder-docker-prod-local.jfrog.io/canary_forwarder"` | The image repository to pull from<br> <REPLACE_WITH_YOUR_REGISTRY>/canary_forwarder |
| image.tag | string | `nil` | Required. Tag of the image to deploy. |
| imagePullSecrets | list | `[]` | Secret that stores credentials that are used for accessing the container registry |
| labels | object | `{}` | Additional labels to add to all the resources created by this chart. |
| nameOverride | string | `""` | String to partially override linux-edr-sensor.fullname template (will maintain the release name) |
| persistence.accessModes | list | `["ReadWriteMany"]` | The access mode for the persistent volumes. When using a daemonset, the access mode will likely be 'ReadWriteMany'. Note that not all storage classes support all access modes. https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes |
| persistence.enabled | bool | `true` | Whether or not persistent storage should be used for the sensor's /tmp and /logs data. |
| persistence.logDir | string | `"/var/log"` | The path on the host to use for persistent log storage. Only used when type is set to 'hostpath'. |
| persistence.logVolumeSize | string | `"512m"` | The size of the persistent volume for log data. |
| persistence.storageClass | string | `nil` | The name of the storage class to use when using a pvc. If not provided, the default storage class will be used. |
| persistence.tmpDir | string | `"/tmp"` | The path on the host to use for persistent tmp storage. Only used when type is set to 'hostpath'. |
| persistence.tmpVolumeSize | string | `"512m"` | The size of the persistent volume for tmp data. |
| persistence.type | string | `"hostpath"` | Type of persistent storage to use. Options are 'hostpath' or 'pvc'. Use hostpath when using the node's storage, and pvc when using a storage class. |
| podAnnotations | object | `{}` | Additional annotations for the deployed pod(s). |
| resources | object | `{}` | Sets the allocated CPU and memory specifications for the pod(s). |
| securityContext | object | `{"privileged":true}` | Pod security context. Note: the container must be privileged. Linux EDR requires access to proc filesystem elements that, in the Docker security model, can not be granted to an unprivileged container via capabilities. |
| tolerations | string | `nil` | Tolerations allow the pod to be scheduled onto nodes with specific taints. Examples can be uncommented if needed for well-known control-plane taints. |

----------------------------------------------
<br>
Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs). Any changes to README.md will be overwriten.

To regenerate this document, from the root of this chart directory run:
```shell
docker run --rm --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest
```