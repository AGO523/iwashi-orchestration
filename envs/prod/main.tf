provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source        = "../../modules/network"
  vpc_name      = "private-vpc"
  subnet_name   = "private-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
}

module "iam" {
  source     = "../../modules/iam"
  project_id = var.project_id
}

module "pubsub" {
  source     = "../../modules/pubsub"
  topic_name = "client-message-topic"
}

module "api_gateway" {
  source         = "../../modules/api_gateway"
  api_id         = "publish-api"
  api_config_id  = "publish-config"
  gateway_id     = "publish-gateway"
  openapi_path   = "openapi.yaml"
  region         = var.region
}

module "artifact_registry" {
  source        = "../../modules/artifact_registry"
  repository_id = "node-news-notification"
  region        = var.region
  description   = "Repository for Cloud Run Job Docker images"
}

module "job_scheduler" {
  source                = "../../modules/job_scheduler"
  job_name              = "pubsub-pull-job"
  region                = var.region
  image                 = "asia-northeast1-docker.pkg.dev/${var.project_id}/node-news-notification/node-news-notification:latest"
  pubsub_topic          = module.pubsub.topic_name
  service_account_email = module.iam.service_account_email
  scheduler_name        = "cloud-run-job-trigger"
  description           = "Trigger Cloud Run Job every day"
  schedule              = "0 0 * * *"
  time_zone             = "Asia/Tokyo"
  cloud_run_job_uri     = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/pubsub-pull-job:run"
}
