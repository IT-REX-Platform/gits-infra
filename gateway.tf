resource "kubernetes_deployment" "gits_graphql_gateway" {
  depends_on = [helm_release.dapr, helm_release.keel, kubernetes_secret.image_pull]
  metadata {
    name = "gits-gateway"
    labels = {
      app = "gits-gateway"
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
        app = "gits-gateway"
      }
    }

    template {
      metadata {
        labels = {
          app = "gits-gateway"

        }
      }

      spec {

        image_pull_secrets {
          name = kubernetes_secret.image_pull.metadata[0].name
        }


        container {
          image             = "ghcr.io/it-rex-platform/graphql_gateway:latest"
          image_pull_policy = "Always"

          name = "gits-gateway"

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
            name  = "GATEWAY_HOSTNAME"
            value = "0.0.0.0"
          }
          env {
            name  = "GATEWAY_PORT"
            value = "8080"
          }
          env {
            name  = "COURSE_SERVICE_URL"
            value = "http://gits-course-service/graphql"
          }
          env {
            name  = "MEDIA_SERVICE_URL"
            value = "http://gits-media-service/graphql"
          }
          env {
            name  = "CONTENT_SERVICE_URL"
            value = "http://gits-content-service/graphql"
          }
          env {
            name  = "JWKS_URL"
            value = "http://keycloak:80/keycloak/realms/GITS/protocol/openid-connect/certs"
          }


          liveness_probe {
            http_get {
              path = "/graphql"
              port = 8080

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }

          readiness_probe {
            http_get {
              path = "/graphql"
              port = 8080

            }

            initial_delay_seconds = 30
            period_seconds        = 9
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "gits_graphql_gateway" {
  metadata {
    name      = "gits-graphql-gateway"
    namespace = kubernetes_namespace.gits.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.gits_graphql_gateway.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "NodePort"
  }
}
