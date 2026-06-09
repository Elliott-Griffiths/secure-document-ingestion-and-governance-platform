# 1. Cloud Run API Server (Min Instances: 1 to mitigate cold starts)
resource "google_cloud_run_v2_service" "api_server" {
  name     = "gov-api-server-${var.environment}"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY" # Restricted to perimeter Gateway access

  template {
    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" # Bootstrap container image

      resources {
        limits = {
          cpu    = "1.0"
          memory = "512Mi"
        }
      }
    }
  }
}

# 2. Cloud Run Security UI (Min Instances: 0 for cost-effective scale-to-zero)
resource "google_cloud_run_v2_service" "security_ui" {
  name     = "gov-security-ui-${var.environment}"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY" # Restricted to internal network safeguarding officers

  template {
    service_account = var.security_ui_sa_email

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello" # Bootstrap container image

      resources {
        limits = {
          cpu    = "1.0"
          memory = "512Mi"
        }
      }
    }
  }
}

# 3. Cloud Secret Manager for credentials/API keys
resource "google_secret_manager_secret" "application_secrets" {
  secret_id = "gov-app-secrets-${var.environment}"
  project   = var.project_id

  replication {
    automatic = true
  }
}
