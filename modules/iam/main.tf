resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-app-sa"
  display_name = "Cloud Run app service account"
}

resource "google_project_iam_member" "invoker" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

output "service_account_email" {
  value = google_service_account.cloud_run.email
}

resource "google_service_account" "gateway" {
  account_id   = "api-gateway-sa"
  display_name = "Service Account for API Gateway"
}

resource "google_project_iam_member" "cloudrun_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.gateway.email}"
}

output "gateway_service_account_email" {
  value = google_service_account.gateway.email
}

# GitHub Actions 用 Service Account
resource "google_service_account" "gh_oidc" {
  account_id   = "gh-oidc"
  display_name = "GitHub OIDC"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "gh_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "oidc-pool-v3"
  display_name              = "OIDC Pool v3"
  description               = "Workload Identity Federation Pool for GitHub Actions"
}

# Workload Identity Pool Provider
resource "google_iam_workload_identity_pool_provider" "provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.gh_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "oidc-gh-provider-v3"

  display_name = "GitHub OIDC Provider v3"
  description  = "OIDC provider for GitHub Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = <<EOT
    attribute.repository == "AGO523/node-news-notification"
  EOT
}

data "google_project" "project" {
  project_id = var.project_id
}

# Service Account に Workload Identity User 権限を付与
resource "google_service_account_iam_member" "github_oidc_binding" {
  service_account_id = google_service_account.gh_oidc.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gh_pool.workload_identity_pool_id}/attribute.repository/AGO523/node-news-notification"
}

resource "google_project_iam_member" "gh_oidc_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gh_oidc.email}"
}
