variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "image" {
  type        = string
  description = "Docker image URL"
}

variable "api_key" {
  type        = string
  description = "API key for internal use"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "gateway_service_account_email" {
  type        = string
  description = "Service account email for API Gateway"
}

variable "service_account_email" {
  type        = string
  description = "Service account email for Cloud Run"
}
