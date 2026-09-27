variable "tenant_namespace" {
  type = string
}
variable "argocd_namespace" {
  type = string
}
variable "monitoring_ns" {
  type = string
}

# --- GitOps controller ---------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = var.argocd_namespace
  create_namespace = true
}

# --- Progressive delivery engine -----------------------------------------
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = "2.36.1"
  namespace        = var.argocd_namespace
  create_namespace = true
}

# --- Policy-as-code governance --------------------------------------------
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno"
  chart            = "kyverno"
  version          = "3.2.6"
  namespace        = "kyverno"
  create_namespace = true
}

# --- Metrics stack (feeds Argo Rollouts AnalysisTemplates) ---------------
resource "helm_release" "kube_prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "62.7.0"
  namespace        = var.monitoring_ns
  create_namespace = true

  set {
    name  = "grafana.enabled"
    value = "true"
  }
}

# --- FinOps: per-namespace cost visibility --------------------------------
resource "helm_release" "opencost" {
  name             = "opencost"
  repository       = "https://opencost.github.io/opencost-helm-chart"
  chart            = "opencost"
  namespace        = var.monitoring_ns
  create_namespace = true

  set {
    name  = "opencost.exporter.defaultClusterId"
    value = "adcash-idp-dev-cluster"
  }

  set {
    name  = "prometheus.internal.serviceName"
    value = "prometheus-kube-prometheus-prometheus"
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
