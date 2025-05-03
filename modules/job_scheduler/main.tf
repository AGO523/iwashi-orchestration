resource "google_cloud_run_v2_job" "job" {
  name     = var.job_name
  location = var.region

  template {
    template {
    service_account = var.service_account_email
      containers {
        image = var.image
        env {
          name  = "PUBSUB_TOPIC"
          value = var.pubsub_topic
        }
      }
    }
  }
}

resource "google_cloud_scheduler_job" "scheduler" {
  name        = var.scheduler_name
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone

  http_target {
    uri         = var.cloud_run_job_uri
    http_method = "POST"
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
}
