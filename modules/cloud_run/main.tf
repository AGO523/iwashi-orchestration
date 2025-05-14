resource "google_cloud_run_service" "app" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.image
        env {
          name  = "API_KEY"
          value = var.api_key
        }
      }
      service_account_name = var.service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

output "cloudrun_url" {
  value = google_cloud_run_service.app.status[0].url
}

resource "google_cloud_run_service_iam_member" "gateway_invoker" {
  location = var.region
  service  = google_cloud_run_service.app.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.gateway_service_account_email}"
}
