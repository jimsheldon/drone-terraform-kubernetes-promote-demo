resource "kubernetes_deployment" "podinfo" {
  metadata {
    name      = "podinfo-promote"
    namespace = var.namespace
  }

  spec {
    selector {
      match_labels = {
        app = "podinfo-promote"
      }
    }

    template {
      metadata {
        labels = {
          app = "podinfo-promote"
        }

        annotations = {
          "prometheus.io/port"   = "9797"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        container {
          name  = "podinfod"
          image = "ghcr.io/stefanprodan/podinfo:6.1.1"
          command = [
            "./podinfo",
            "--port=9898",
            "--port-metrics=9797",
            "--grpc-port=9999",
            "--grpc-service-name=podinfo",
            "--level=info",
            "--random-delay=false",
            "--random-error=false"
          ]

          port {
            name           = "http"
            container_port = 9898
            protocol       = "TCP"
          }

          port {
            name           = "http-metrics"
            container_port = 9797
            protocol       = "TCP"
          }

          port {
            name           = "grpc"
            container_port = 9999
            protocol       = "TCP"
          }

          env {
            name  = "PODINFO_UI_MESSAGE"
            value = "running in ${var.namespace} namespace! hello Conf42!"
          }
          env {
            name  = "PODINFO_UI_COLOR"
            value = var.ui_color
          }

          resources {
            limits = {
              cpu = "2"

              memory = "512Mi"
            }

            requests = {
              cpu = "100m"

              memory = "64Mi"
            }
          }

          liveness_probe {
            exec {
              command = ["podcli", "check", "http", "localhost:9898/healthz"]
            }

            initial_delay_seconds = 5
            timeout_seconds       = 5
          }

          readiness_probe {
            exec {
              command = ["podcli", "check", "http", "localhost:9898/readyz"]
            }

            initial_delay_seconds = 5
            timeout_seconds       = 5
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }

    strategy {
      type = "RollingUpdate"
    }

    min_ready_seconds         = 3
    revision_history_limit    = 5
    progress_deadline_seconds = 60
  }
}
