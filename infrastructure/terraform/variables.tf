variable "kubeconfig_path" {
  description = "Path to the kubeconfig written by Kind."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubectl context of the Kind cluster (kind-<cluster name>)."
  type        = string
  default     = "kind-cloudpilot"
}

variable "app_namespace" {
  description = "Namespace that Argo CD / Helm deploys the application into."
  type        = string
  default     = "cloudpilot"
}

variable "monitoring_namespace" {
  description = "Namespace for Prometheus and Grafana (only used in monitoring modes)."
  type        = string
  default     = "monitoring"
}

variable "app_quota" {
  description = "ResourceQuota for the application namespace (sized for an 8 GB laptop)."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    pods            = string
  })
  default = {
    requests_cpu    = "500m"
    requests_memory = "512Mi"
    limits_cpu      = "1"
    limits_memory   = "1Gi"
    pods            = "10"
  }
}

variable "monitoring_quota" {
  description = "ResourceQuota for the monitoring namespace."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    pods            = string
  })
  default = {
    requests_cpu    = "1"
    requests_memory = "1Gi"
    limits_cpu      = "2"
    limits_memory   = "2Gi"
    pods            = "10"
  }
}

variable "container_default_request" {
  description = "LimitRange default request applied to containers that declare none."
  type        = object({ cpu = string, memory = string })
  default     = { cpu = "25m", memory = "32Mi" }
}

variable "container_default_limit" {
  description = "LimitRange default limit applied to containers that declare none."
  type        = object({ cpu = string, memory = string })
  default     = { cpu = "200m", memory = "256Mi" }
}

variable "container_max" {
  description = "LimitRange maximum for any single container."
  type        = object({ cpu = string, memory = string })
  default     = { cpu = "1", memory = "1Gi" }
}
