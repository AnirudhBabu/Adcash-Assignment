variable "kubeconfig_path" {
  description = "Path to kubeconfig for the target cluster (kind/minikube/EKS/AKS)"
  type        = string
  default     = "~/.kube/config"
}

variable "tenant_namespace" {
  description = "Namespace for the staging tenant workload"
  type        = string
  default     = "staging"
}

variable "argocd_namespace" {
  type    = string
  default = "argocd"
}

variable "monitoring_namespace" {
  type    = string
  default = "monitoring"
}
