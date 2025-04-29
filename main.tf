terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
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

# 2. Serverless VPC Connector作成
resource "google_vpc_access_connector" "serverless_connector" {
  name          = "serverless-connector"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
}

# 3. Pub/Subトピック作成
resource "google_pubsub_topic" "topic" {
  name = "client-message-topic"
}

# 4. API Gateway API作成
resource "google_api_gateway_api" "api" {
  api_id = "publish-api"
}

# 5. API Gateway Config作成
resource "google_api_gateway_api_config" "api_config" {
  api      = google_api_gateway_api.api.api_id
  api_config_id = "publish-config"

  openapi_documents {
    path = "openapi.yaml"
  }
}

# 6. API Gateway Gateway作成
resource "google_api_gateway_gateway" "gateway" {
  gateway_id = "publish-gateway"
  api_config = google_api_gateway_api_config.api_config.id
  region     = var.region
}

# 7. APIキー作成
resource "google_api_key" "client_key" {
  display_name = "client-api-key"
}

# 8. Cloud Run Job作成
resource "google_cloud_run_v2_job" "job" {
  name     = "pubsub-pull-job"
  location = var.region

  template {
    template {
      containers {
        image = "gcr.io/${var.project_id}/news-mailer"
        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.topic.name
        }
      }
      vpc_access {
        connector = google_vpc_access_connector.serverless_connector.id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
  }
}

# 9. Cloud Scheduler作成
resource "google_cloud_scheduler_job" "scheduler" {
  name             = "cloud-run-job-trigger"
  description      = "Trigger Cloud Run Job every day"
  schedule         = "0 0 1 * *"
  time_zone        = "Asia/Tokyo"

  http_target {
    uri = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"
    http_method = "POST"
    oidc_token {
      service_account_email = "terraform@${var.project_id}.iam.gserviceaccount.com"
    }
  }
}
