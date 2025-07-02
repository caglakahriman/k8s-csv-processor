{{/*
Expand the name of the chart.
*/}}
{{- define "csv-processor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "csv-processor.fullname" -}}
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
{{- define "csv-processor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "csv-processor.labels" -}}
helm.sh/chart: {{ include "csv-processor.chart" . }}
{{ include "csv-processor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "csv-processor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "csv-processor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "csv-processor.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "csv-processor.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pod Annotations
*/}}
{{- define "pod-annotations" -}}
annotations:
  sidecar.istio.io/inject: "true"
  timestamp: {{ now | quote }}
{{ with .Values.podAnnotations }}
    {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Create the environment variables configuration
*/}}
{{- define "csv-processor.environment" -}}
{{- range $key, $val := .Values.environment }}
- name: {{ $key }}
  value: {{ $val | quote -}}
{{- end -}}
{{- end -}}

{{/*
Create the secret environment variables configuration
*/}}
{{- define "csv-processor.environmentSecret" -}}
{{- range $name, $secretKeyRefName := .Values.environmentSecret }}
- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "csv-processor.fullname" $ }}-secret
      key: {{ $secretKeyRefName | quote -}}
{{- end -}}
{{- end -}}