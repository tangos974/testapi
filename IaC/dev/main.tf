resource "google_artifact_registry_repository" "default" {
  format        = "DOCKER"
  location      = var.default_region
  repository_id = var.app_name
  project       = var.project_id
}

# Service Account for CI/CD
resource "google_service_account" "cicd_sa" {
  account_id   = "cicd-sa"
  display_name = "CI/CD Service Account"
  project      = var.project_id
}

resource "google_project_iam_binding" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"

  members = [
    "serviceAccount:${google_service_account.cicd_sa.email}"
  ]
}

resource "google_project_iam_binding" "artifact_registry_accesses" {
  role    = "roles/artifactregistry.reader"
  project = var.project_id
  members = [
    "serviceAccount:${google_service_account.cloud_run_sa.email}",
    "serviceAccount:${google_service_account.cicd_sa.email}"
  ]
}

resource "google_project_iam_binding" "cloud_run_editor" {
  project = var.project_id
  role    = "roles/run.developer"

  members = [
    "serviceAccount:${google_service_account.cicd_sa.email}"
  ]
}

resource "google_project_iam_binding" "cicd_sa_impersonation" {
  role    = "roles/iam.serviceAccountUser"
  project = var.project_id
  members = [
    "serviceAccount:${google_service_account.cicd_sa.email}"
  ]
}

# Empty Service Account for Cloud Run (Not empty has ar access rights)
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
  project      = var.project_id
}

# Allow unauthenticated access to the Cloud Run service 
# For example purposes, in reality devs emails would be used
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "policy" {
  location = var.default_region
  project  = var.project_id
  name = google_cloud_run_v2_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_v2_service" "default" {
  name     = var.app_name
  location = var.default_region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  deletion_protection = false
  template {
      scaling {
        min_instance_count = 0
        max_instance_count = 1
      }
    containers {
      image = "${var.default_region}-docker.pkg.dev/${var.project_id}/${var.app_name}/${var.app_name}:latest"
      ports {
        container_port = 80
      }
      liveness_probe {
        http_get {
          path = "/health"
        }
      }
    }
    service_account = google_service_account.cloud_run_sa.email
  }

  traffic {
    type        = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent     = 100
  }
}
