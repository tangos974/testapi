terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.15.0"
    }
  }
  required_version = ">= 1.10.3"
}