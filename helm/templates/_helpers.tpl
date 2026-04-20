{{/*
Expand the name of the chart.
*/}}
{{- define "resourcespace.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "resourcespace.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "resourcespace.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for the ResourceSpace Deployment.
*/}}
{{- define "resourcespace.selectorLabels" -}}
app.kubernetes.io/name: resourcespace
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for the MariaDB StatefulSet.
*/}}
{{- define "mariadb.selectorLabels" -}}
app.kubernetes.io/name: mariadb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Secret holding database credentials.
*/}}
{{- define "mariadb.secretName" -}}
{{ include "resourcespace.fullname" . }}-mariadb-secret
{{- end }}

{{/*
Internal DNS name of the MariaDB Service (used by ResourceSpace config.php).
*/}}
{{- define "mariadb.serviceName" -}}
{{ include "resourcespace.fullname" . }}-mariadb
{{- end }}

{{/*
Validate required values are set before deploying.
*/}}
{{- define "resourcespace.validateValues" -}}
{{- if not .Values.mariadb.auth.rootPassword }}
  {{- fail "ERROR: mariadb.auth.rootPassword must be set. Use --set mariadb.auth.rootPassword=<value>" }}
{{- end }}
{{- if not .Values.mariadb.auth.password }}
  {{- fail "ERROR: mariadb.auth.password must be set. Use --set mariadb.auth.password=<value>" }}
{{- end }}
{{- if not .Values.resourcespace.hostname }}
  {{- fail "ERROR: resourcespace.hostname must be set. Use --set resourcespace.hostname=<your-cluster-hostname>" }}
{{- end }}
{{- if not .Values.resourcespace.image.repository }}
  {{- fail "ERROR: resourcespace.image.repository must be set. Build the image from https://github.com/resourcespace/docker and push to your registry." }}
{{- end }}
{{- end }}
