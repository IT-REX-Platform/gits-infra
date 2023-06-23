resource "kubernetes_deployment" "gits_flashcard_service" {
  depends_on = [helm_release.flashcard_service_db, helm_release.dapr, helm_release.keel, kubernetes_secret.image_pull]
  metadata {
    name = "gits-flashcard-service"
    labels = {
      app = "gits-flashcard-service"
    }
    namespace = kubernetes_namespace.gits.metadata[0].name
    annotations = {
      "keel.sh/policy"    = "force"
      "keel.sh/match-tag" = "true"
      "keel.sh/trigger"   = "poll"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gits-flashcard-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-flashcard-service"
        }
        annotations = {
          "dapr.io/enabled"  = false
          "dapr.io/app-id"   = "media-service"
          "dapr.io/app-port" = 3000
        }
      }

      spec {

        image_pull_secrets {
          name = kubernetes_secret.image_pull.metadata[0].name
        }


        container {
          image             = "ghcr.io/it-rex-platform/flashcard_service:latest"
          image_pull_policy = "Always"

          name = "gits-flashcard-service"

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
            value = "jdbc:postgresql://flashcard-service-db-postgresql:5432/flashcard-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.flashcard_service_db_pass.result
          }

          # liveness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 4001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 4001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }
        }
      }
    }
  }
}

resource "random_password" "flashcard_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "flashcard_service_db" {
  name       = "flashcard-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "global.postgresql.auth.database"
    value = "flashcard-service"
  }

  set {
    name  = "postgres.auth.enablePostgresUser"
    value = "false"
  }

  set {
    name  = "global.postgresql.auth.username"
    value = "gits"
  }

  set {
    name  = "global.postgresql.auth.password"
    value = random_password.flashcard_service_db_pass.result
  }
}

resource "kubernetes_service" "gits_flashcard_service" {
  metadata {
    name      = "gits-flashcard-service"
    namespace = kubernetes_namespace.gits.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.gits_flashcard_service.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 3001
    }

    type = "NodePort"
  }
}
