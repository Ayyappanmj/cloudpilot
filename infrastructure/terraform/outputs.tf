output "namespaces" {
  description = "Namespaces managed by Terraform."
  value       = [for ns in kubernetes_namespace_v1.this : ns.metadata[0].name]
}

output "app_namespace" {
  value = kubernetes_namespace_v1.this[var.app_namespace].metadata[0].name
}

output "app_quota_hard" {
  description = "Hard limits enforced in the application namespace."
  value       = kubernetes_resource_quota_v1.this[var.app_namespace].spec[0].hard
}

output "verify_command" {
  value = "kubectl get ns,resourcequota,limitrange -n ${var.app_namespace}"
}
