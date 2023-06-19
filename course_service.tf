resource "kubernetes_deployment" "gits_course_service" {
  metadata {
    name = "gits-course-service"
    labels = {
      app = "gits-course-service"
    }
    namespace = kubernetes_namespace.gits.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gits-course-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-course-service"

        }
        annotations = {
          "dapr.io/app-id"   = "course-service"
          "dapr.io/app-port" = 4000
        }

      }

      spec {

        image_pull_secrets {
          name = "github-pull-secret"
        }


        container {
          image = "ghcr.io/it-rex-platform/course_service:latest"
          name  = "gits-course-service"

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
            value = "jdbc:postgresql://course-service-db-postgresql:5432/course-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.course_service_db_pass.result
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

resource "random_password" "course_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "course_service_db" {
  name       = "course-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "postgresql.auth.database"
    value = "course-service"
  }

  set {
    name  = "postgresql.auth.enablePostgresUser"
    value = "false"
  }

  set {
    name  = "postgresql.auth.username"
    value = "gits"
  }

  set {
    name  = "postgresql.auth.password"
    value = random_password.course_service_db_pass.result
  }
}
