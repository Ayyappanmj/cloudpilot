# Terraform owns FOUNDATIONAL objects: namespaces, quotas, limit ranges.
# Argo CD / Helm own everything inside the application namespace (Deployment, Service, ...).
# Neither tool manages the other's resources, so they never fight over drift.

locals {
  namespaces = {
    (var.app_namespace)        = { quota = var.app_quota, pss_enforce = "restricted" }
    (var.monitoring_namespace) = { quota = var.monitoring_quota, pss_enforce = "baseline" }
  }
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespaces

  metadata {
    name = each.key
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = each.value.pss_enforce
    }
  }
}

resource "kubernetes_resource_quota_v1" "this" {
  for_each = local.namespaces

  metadata {
    name      = "default-quota"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = each.value.quota.requests_cpu
      "requests.memory" = each.value.quota.requests_memory
      "limits.cpu"      = each.value.quota.limits_cpu
      "limits.memory"   = each.value.quota.limits_memory
      "pods"            = each.value.quota.pods
    }
  }
}

resource "kubernetes_limit_range_v1" "this" {
  for_each = local.namespaces

  metadata {
    name      = "default-limits"
    namespace = kubernetes_namespace_v1.this[each.key].metadata[0].name
  }

  spec {
    limit {
      type            = "Container"
      default         = var.container_default_limit
      default_request = var.container_default_request
      max             = var.container_max
    }
  }
}
