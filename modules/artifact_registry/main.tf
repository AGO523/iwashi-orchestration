resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google-beta
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description
}

output "repository_url" {
  value = "asia-northeast1-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}
