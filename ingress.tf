

resource "kubernetes_ingress_v1" "gits" {
  metadata {
    name      = "gits"
    namespace = kubernetes_namespace.gits.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }

  }

  spec {
    default_backend {
      service {
        name = "gits-frontend"
        port {
          number = 3000
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = "gits-frontend"
              port {
                number = 3000
              }
            }
          }

          path = "/"
        }
      }
    }
  }
}
