{{- define "order-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "order-service.fullname" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{- define "order-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- printf "%s-sa" (include "order-service.fullname" .) -}}
{{- end -}}
{{- end }}
