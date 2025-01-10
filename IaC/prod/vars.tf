variable "project_id" {
  description = "The ID of the GCP project associated to the environment"
  type        = string
  default = "test-api-prod"
}

variable "env_name" {
  description = "The name of the environment"
  type        = string
  default = "prod"
}

output "env_name" {
  value = var.env_name
}

variable "app_name" {
  description = "The name of the application"
  type        = string
  default = "tanguys-test-api"
}

output "app_name" {
  value = var.app_name
}

variable "default_region" {
  description = "The default region for all resources in the GCP project"
  type        = string
  default = "europe-west1"
}

output "default_region" {
  value = var.default_region
}

variable "default_zone" {
    description = "Default zone accompanying default region"
    type = string
    default = "europe-west1-b"
}

output "default_zone" {
  value = var.default_zone  
}