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
          image = "ghcr.io/it-rex-platform/content_service:latest"
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

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:postgresql://content-service-db:5432/content-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.content_service_db_pass.result
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

resource "random_password" "content_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "content_service_db" {
  name       = "content-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "auth.database"
    value = "content-service"
  }

  set {
    name  = "auth.enablePostgresUser"
    value = "false"
  }

  set {
    name  = "auth.username"
    value = "gits"
  }

  set {
    name  = "auth.password"
    value = random_password.content_service_db_pass.result
  }
}
