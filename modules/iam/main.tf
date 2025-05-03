resource "google_service_account" "app" {
  account_id   = "app-job-executor"
  display_name = "Service Account for Cloud Run Job and Scheduler"
}

resource "google_project_iam_member" "app_run_job_executor" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.app.email}"
}

resource "google_project_iam_member" "app_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.app.email}"
}

output "service_account_email" {
  value = google_service_account.app.email
}
