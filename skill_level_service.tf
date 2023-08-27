resource "kubernetes_deployment" "gits_skill_level_service" {
  depends_on = [helm_release.skill_level_service_db, helm_release.dapr, helm_release.keel, kubernetes_secret.image_pull]
  metadata {
    name = "gits-skill-level-service"
    labels = {
      app = "gits-skill-level-service"
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
        app = "gits-skill-level-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-skill-level-service"
        }
        annotations = {
          "dapr.io/enabled"   = true
          "dapr.io/app-id"    = "skill_level-service"
          "dapr.io/app-port"  = 9001
          "dapr.io/http-port" = 9000
        }
      }

      spec {

        image_pull_secrets {
          name = kubernetes_secret.image_pull.metadata[0].name
        }


        container {
          image             = "ghcr.io/it-rex-platform/skill_level_service:latest"
          image_pull_policy = "Always"

          name = "gits-skill-level-service"

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
            value = "jdbc:postgresql://skill_level-service-db-postgresql:5432/skill_level-service"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "gits"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = random_password.skill_level_service_db_pass.result
          }

          env {
            name  = "COURSE_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/course-service/method/graphql"
          }

          env {
            name  = "CONTENT_SERVICE_URL"
            value = "http://localhost:3500/v1.0/invoke/content-service/method/graphql"
          }


          # liveness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 7001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/graphql"
          #     port = 7001

          #   }

          #   initial_delay_seconds = 30
          #   period_seconds        = 9
          # }
        }
      }
    }
  }
}

resource "random_password" "skill_level_service_db_pass" {
  length  = 32
  special = false
}

resource "helm_release" "skill_level_service_db" {
  name       = "skill_level-service-db"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.gits.metadata[0].name

  set {
    name  = "global.postgresql.auth.database"
    value = "skill_level-service"
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
    value = random_password.skill_level_service_db_pass.result
  }
}


