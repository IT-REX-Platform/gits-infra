resource "kubernetes_deployment" "gits_media_service" {
  depends_on = [helm_release.media_service_db, helm_release.dapr, helm_release.keel, kubernetes_secret.image_pull, helm_release.minio]
  metadata {
    name = "gits-media-service"
    labels = {
      app = "gits-media-service"
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
        app = "gits-media-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-media-service"
        }
        annotations = {
          "dapr.io/enabled"   = true
          "dapr.io/app-id"    = "media-service"
          "dapr.io/app-port"  = 3001
          "dapr.io/http-port" = 3000
        }
      }

      spec {

        image_pull_secrets {
          name = kubernetes_secret.image_pull.metadata[0].name
        }


        container {
          image             = "ghcr.io/it-rex-platform/media_service:latest"
          image_pull_policy = "Always"

          name = "gits-media-service"

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
            value = "jdbc:postgresql://media-service-db-postgresql:5432/media-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.media_service_db_pass.result
          }

          env {
            name  = "MINIO_URL"
            value = "minio"
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = "gits"
          }
          env {
            name  = "MINIO_ACCESS_SECRET"
            value = random_password.media_service_minio_pass.result
          }

          # liveness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 3001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 3001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }
        }
      }
    }
  }
}

resource "random_password" "media_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "media_service_db" {
  name       = "media-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "global.postgresql.auth.database"
    value = "media-service"
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
    value = random_password.media_service_db_pass.result
  }
}


resource "random_password" "media_service_minio_pass" {
  length  = 32
  special = false
}

resource "helm_release" "minio" {
  name       = "minio"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "minio"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "auth.rootUser"
    value = "gits"
  }

  set {
    name  = "auth.rootPassword"
    value = random_password.media_service_minio_pass.result
  }
  set {
    name  = "extraEnvVars[0].name"
    value = "MINIO_BROWSER_REDIRECT_URL"
  }
  set {
    name  = "extraEnvVars[0].value"
    value = "https://orange.informatik.uni-stuttgart.de/minio"
  }
}
