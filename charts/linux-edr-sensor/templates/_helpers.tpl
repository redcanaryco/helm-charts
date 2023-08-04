{{/*
Expand the name of the chart.
*/}}
{{- define "linux-edr-sensor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "linux-edr-sensor.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "linux-edr-sensor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "linux-edr-sensor.labels" -}}
helm.sh/chart: {{ include "linux-edr-sensor.chart" . }}
{{ include "linux-edr-sensor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "linux-edr-sensor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linux-edr-sensor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Sensor Config
*/}}
{{- define "linux-edr-sensor.config" -}}
access_token: {{ required "A valid access token is required." .Values.config.accessToken }}
offload_target: Outpost
outpost_auth_token: {{ required "A valid Outpost auth token is required." .Values.config.outpostAuthToken }}
{{- with .Values.config.extraOptions }}
{{ . | toYaml }}
{{- end }}
{{- with .Values.config.telemetrySource }}
telemetry:
  source: {{ . }}
{{- end }}
{{- with .Values.config.reportingTags }}
reporting_tags:
{{- . | toYaml | nindent 2 }}
{{- end }}
{{- end }}
