# 作成したAPIは有効化しないと使用できないことに注意
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = var.api_id
}

resource "google_api_gateway_api_config" "api_config" {
  provider     = google-beta
  api          = google_api_gateway_api.api.api_id
  api_config_id = var.api_config_id

  openapi_documents {
    document {
      path     = var.openapi_path
      contents = filebase64(var.openapi_path)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  gateway_config {
    backend_config {
      google_service_account = var.service_account_email
    }
  }
}

resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  gateway_id = var.gateway_id
  api_config = google_api_gateway_api_config.api_config.id
  region     = var.region
}

output "api_name" {
  value = google_api_gateway_api.api.name
}
