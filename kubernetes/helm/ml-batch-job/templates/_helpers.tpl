{{/*
_helpers.tpl
Shared named templates for the ml-batch-job chart.
Conventions mirror sample-app/_helpers.tpl for platform consistency.
*/}}

{{/*
Chart name — trimmed to 63 characters (Kubernetes label value limit).
*/}}
{{- define "ml-batch-job.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified release name.
Avoids doubling the name when the release name already contains the chart name.
*/}}
{{- define "ml-batch-job.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $chartName := default .Chart.Name .Values.nameOverride }}
{{- if contains $chartName .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $chartName | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label value — used in helm.sh/chart annotation.
*/}}
{{- define "ml-batch-job.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource managed by this chart.
*/}}
{{- define "ml-batch-job.labels" -}}
helm.sh/chart: {{ include "ml-batch-job.chart" . }}
{{ include "ml-batch-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: ml-platform
{{- end }}

{{/*
Selector labels — used in Job selectors and pod template labels.
Must remain stable across chart upgrades.
*/}}
{{- define "ml-batch-job.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ml-batch-job.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod template labels — selector labels plus the labels required by the
require-pod-labels Kyverno policy (ADR conflict C08). Kept separate from
selectorLabels so that Job selectors stay stable across upgrades.
*/}}
{{- define "ml-batch-job.podLabels" -}}
{{ include "ml-batch-job.selectorLabels" . }}
app.kubernetes.io/part-of: ml-platform
env: {{ required "environment is required (e.g. dev)" .Values.environment | quote }}
{{- end }}

{{/*
ServiceAccount name resolution.
Uses explicit name if provided, otherwise <fullname>-sa.
The -sa suffix makes the resource type explicit in kubectl output.
*/}}
{{- define "ml-batch-job.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- printf "%s-sa" (include "ml-batch-job.fullname" .) }}
{{- end }}
{{- end }}

{{/*
GPU Job name — runId suffix allows sequential runs without deleting
the previous Completed job. Kubernetes rejects duplicate Job names.
*/}}
{{- define "ml-batch-job.gpuJobName" -}}
{{- printf "%s-extract-%s" (include "ml-batch-job.fullname" .) .Values.job.runId | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
CPU Job name — same runId convention as the GPU job.
*/}}
{{- define "ml-batch-job.cpuJobName" -}}
{{- printf "%s-train-%s" (include "ml-batch-job.fullname" .) .Values.job.runId | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Metrics sidecar image resolution.
Falls back to the CPU image when no dedicated sidecar image is specified.
This avoids pulling a second image when the CPU image already embeds the exporter.
*/}}
{{- define "ml-batch-job.metricsImage" -}}
{{- if .Values.metrics.image.repository }}
{{- printf "%s:%s" .Values.metrics.image.repository .Values.metrics.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.image.cpu.repository .Values.image.cpu.tag }}
{{- end }}
{{- end }}

{{/*
Container securityContext for one Job: the chart-wide containerSecurityContext
with the per-Job override (gpu/cpu.containerSecurityContext) merged on top.
deepCopy keeps the shared base untouched across the two Jobs.
Usage: include "ml-batch-job.containerSecurityContext" (dict "root" $ "override" .Values.gpu.containerSecurityContext)
*/}}
{{- define "ml-batch-job.containerSecurityContext" -}}
{{- $baseContext := deepCopy .root.Values.containerSecurityContext -}}
{{- toYaml (mergeOverwrite $baseContext (default dict .override)) -}}
{{- end }}

{{/*
Writable emptyDir mounts that let containers run with a read-only root
filesystem (require-ro-rootfs). Prefixed "scratch-" to never collide with
persistentVolumes names.
*/}}
{{- define "ml-batch-job.scratchVolumeMounts" -}}
{{- range $scratchVolume := .Values.scratchVolumes }}
- name: scratch-{{ $scratchVolume.name }}
  mountPath: {{ $scratchVolume.mountPath }}
{{- end }}
{{- end }}

{{- define "ml-batch-job.scratchVolumes" -}}
{{- range $scratchVolume := .Values.scratchVolumes }}
- name: scratch-{{ $scratchVolume.name }}
  emptyDir:
    sizeLimit: {{ $scratchVolume.sizeLimit | default "1Gi" }}
{{- end }}
{{- end }}
