terraform {
  backend "gcs" {
    bucket = "iwashi-terraform-state"
    prefix = "terraform/state/prod"
  }
}
