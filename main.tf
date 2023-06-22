provider "kubernetes" {
  config_path = "./kubeconfig.yaml"
}
provider "helm" {
  kubernetes {
    config_path = "./kubeconfig.yaml"
  }
}

resource "kubernetes_namespace" "gits" {
  metadata {
    name = "gits"
  }
}

resource "kubernetes_secret" "image_pull" {
  metadata {
    name      = "github-container-secret"
    namespace = kubernetes_namespace.gits.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = var.image_pull_secret
  }

  type = "kubernetes.io/dockerconfigjson"
}

