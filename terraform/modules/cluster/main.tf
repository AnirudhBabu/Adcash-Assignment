variable "tenant_namespace" {
  type = string
}

resource "kubernetes_namespace" "tenant" {
  metadata {
    name = var.tenant_namespace
    labels = {
      "platform.idp/environment"           = var.tenant_namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

resource "kubernetes_resource_quota" "tenant_quota" {
  metadata {
    name      = "${var.tenant_namespace}-quota"
    namespace = kubernetes_namespace.tenant.metadata[0].name
  }
  spec {
    hard = {
      "pods"            = "20"
      "requests.cpu"    = "4"
      "requests.memory" = "8Gi"
      "limits.cpu"      = "8"
      "limits.memory"   = "16Gi"
    }
  }
}

output "tenant_namespace_name" {
  value = kubernetes_namespace.tenant.metadata[0].name
}
