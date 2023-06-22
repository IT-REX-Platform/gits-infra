

resource "kubernetes_ingress_v1" "gits" {
  metadata {
    name      = "gits"
    namespace = kubernetes_namespace.gits.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
      "cert-manager.io/cluster-issuer"                = "ca-issuer"
      "nginx.ingress.kubernetes.io/proxy-body-size"   = "10m"
      "nginx.ingress.kubernetes.io/proxy-buffer-size" = "10m"
    }

  }

  spec {
    default_backend {
      service {
        name = "gits-frontend"
        port {
          number = 80
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

    rule {
      http {
        path {
          backend {
            service {
              name = "gits-graphql-gateway"
              port {
                number = 80
              }
            }
          }

          path = "/graphql"
        }
      }
    }

    rule {
      http {
        path {
          backend {
            service {
              name = "keycloak"
              port {
                number = 80
              }
            }
          }

          path = "/keycloak"
        }
      }
    }
    tls {
      secret_name = "orange-tls-cert"
      hosts       = ["orange.informatik.uni-stuttgart.de"]
    }

  }
}
