resource "helm_release" "dapr" {
  name       = "dapr"
  repository = "https://dapr.github.io/helm-charts"
  chart      = "dapr"
  namespace  = kubernetes_namespace.gits.metadata[0].name
}
