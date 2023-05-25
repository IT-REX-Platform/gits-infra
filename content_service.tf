resource "kubernetes_deployment" "gits_content_service" {
  metadata {
    name = "gits-content-service"
    labels = {
      app = "gits-content-service"
    }
    namespace = kubernetes_namespace.gits.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gits-content-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-content-service"

        }
        annotations = {
          "dapr.io/app-id"   = "content-service"
          "dapr.io/app-port" = 4000
        }

      }

      spec {

        image_pull_secrets {
          name = "github-pull-secret"
        }


        container {
          image = "ghcr.io/it-rex-platform/gits-content_service:0bb8a427"
          name  = "gits-content-service"



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
              port = 4000

            }

            initial_delay_seconds = 9
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "helm_release" "content_service_db" {
  name       = "content-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name
}
