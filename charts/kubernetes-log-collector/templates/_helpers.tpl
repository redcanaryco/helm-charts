{{/*
Expand the name of the chart.
*/}}
{{- define "kubernetes-log-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully-qualifed app name.
We truncate at 63 characters because some Kubernetes name fields are limited to this by the DNS specification.
If release name contains chart name it will be sued as a full name.
*/}}
{{- define "kubernetes-log-collector.fullname" -}}
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
{{- define "kubernetes-log-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubernetes-log-collector.labels" -}}
helm.sh/chart: {{ include "kubernetes-log-collector.chart" . }}
{{ include "kubernetes-log-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubernetes-log-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubernetes-log-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
