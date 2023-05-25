resource "kubernetes_deployment" "gits_frontend" {
  metadata {
    name = "gits-frontend"
    labels = {
      app = "gits-frontend"
    }
    namespace = kubernetes_namespace.gits.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gits-frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-frontend"
        }
      }

      spec {
        container {
          image = "ghcr.io/it-rex-platform/gits-fronted:e01eb5e2"
          name  = "gits-frontend"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000

            }

            initial_delay_seconds = 9
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "gits_frontend" {
  metadata {
    name = "gits-frontend"
  }
  spec {
    selector = {
      app = kubernetes_deployment.gits_frontend.metadata[0].labels.app
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "NodePort"
  }
}

