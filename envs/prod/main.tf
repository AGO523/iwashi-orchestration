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
  gh_repo    = "AGO523/node-news-notification"
}

module "api_gateway" {
  source         = "../../modules/api_gateway"
  api_id         = "request-cloud-run-api"
  api_config_id  = "request-cloud-run-config-v02"
  gateway_id     = "request-cloud-run-gateway"
  openapi_path   = "openapi.yaml"
  region         = var.region
  service_account_email = module.iam.gateway_service_account_email
}

module "artifact_registry" {
  source        = "../../modules/artifact_registry"
  repository_id = "node-news-notification"
  region        = var.region
  description   = "Repository for Cloud Run Job Docker images"
  project_id    = var.project_id
}

module "cloud_run" {
  source        = "../../modules/cloud_run"
  service_name  = "node-news-notification"
  region        = var.region
  image = "${module.artifact_registry.repository_url}/node-news-notification:latest"
  api_key       = var.api_key
  project_id    = var.project_id
  gateway_service_account_email = module.iam.gateway_service_account_email
  service_account_email = module.iam.service_account_email
}
