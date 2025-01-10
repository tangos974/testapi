terraform {
  backend "gcs" {
    bucket = "tanguys-test-api-tf-state"
    prefix = "dev"
  }
}