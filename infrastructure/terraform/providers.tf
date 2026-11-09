# Uses the active Kind kubeconfig. Run scripts/setup-kind first.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
