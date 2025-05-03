terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# state ファイルをGCSに保存
terraform {
  backend "gcs" {
    bucket  = "iwashi-terraform-state"
    prefix  = "terraform/state"
  }
}

# 1. VPCネットワーク作成
resource "google_compute_network" "vpc_network" {
  name                    = "private-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# 2. IAMポリシー設定
resource "google_service_account" "app" {
  account_id   = "app-job-executor"
  display_name = "Service Account for Cloud Run Job and Scheduler"
}

# Cloud Run Job の実行に必要なロール
resource "google_project_iam_member" "app_run_job_executor" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Pub/Sub にアクセスするためのロール（Job内でpullするため）
resource "google_project_iam_member" "app_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# 3. Pub/Subトピック作成
resource "google_pubsub_topic" "topic" {
  name = "client-message-topic"
}

# 4. API Gateway API作成
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id = "publish-api"
}

# 5. API Gateway Config作成
resource "google_api_gateway_api_config" "api_config" {
  provider = google-beta
  api      = google_api_gateway_api.api.api_id
  api_config_id = "publish-config"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = filebase64("openapi.yaml")
    }
  }
}

# 6. API Gateway Gateway作成
resource "google_api_gateway_gateway" "gateway" {
  provider = google-beta
  gateway_id = "publish-gateway"
  api_config = google_api_gateway_api_config.api_config.id
  region     = var.region
}

# 7. Artifact Registry（Dockerリポジトリ）作成
resource "google_artifact_registry_repository" "docker_repo" {
  provider = google-beta

  location      = var.region
  repository_id = "node-news-notification"
  format        = "DOCKER"
  description   = "Repository for Cloud Run Job Docker images"
}



# 8. Cloud Run Job 作成
resource "google_cloud_run_v2_job" "job" {
  name     = "pubsub-pull-job"
  location = var.region

  template {
    template {
      service_account = google_service_account.app.email
      containers {
        image = "asia-northeast1-docker.pkg.dev/${var.project_id}/node-news-notification/node-news-notification:latest"
        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.topic.name
        }
      }
    }
  }
}

# 9. Cloud Scheduler で Cloud Run Job を定期実行
resource "google_cloud_scheduler_job" "scheduler" {
  name        = "cloud-run-job-trigger"
  description = "Trigger Cloud Run Job every day"
  schedule    = "0 0 * * *"
  time_zone   = "Asia/Tokyo"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.app.email
    }
  }
}
