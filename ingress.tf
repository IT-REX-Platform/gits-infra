resource "kubernetes_ingress" "gits" {
  metadata {
    name      = "gits"
    namespace = kubernetes_namespace.gits.metadata[0].name
  }

  spec {
    backend {
      service_name = "gits-frontend"
      service_port = 3000
    }

    rule {
      http {
        path {
          backend {
            service_name = "gits-frontend"
            service_port = 3000
          }

          path = "/"
        }
      }
    }
  }
}
