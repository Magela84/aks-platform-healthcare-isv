{{/* ============================================================
     _helpers.tpl — shared naming + label helpers
     ============================================================ */}}

{{/* App name: explicit nameOverride, else the release name */}}
{{- define "pulsehealth-app.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Standard label set applied to every object */}}
{{- define "pulsehealth-app.labels" -}}
app.kubernetes.io/name: {{ include "pulsehealth-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: pulsehealth
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/* Selector labels — the stable subset used to match pods */}}
{{- define "pulsehealth-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pulsehealth-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name: explicit value, else the app name */}}
{{- define "pulsehealth-app.serviceAccountName" -}}
{{- default (include "pulsehealth-app.name" .) .Values.serviceAccount.name -}}
{{- end -}}
