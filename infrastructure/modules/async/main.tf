# 1. Security Pub/Sub Queue (Immediate security alert topic)
resource "google_pubsub_topic" "security_queue" {
  name    = "gov-security-queue-${var.environment}"
  project = var.project_id
}

# 2. Main Operational Dead-Letter Queue (DLQ) Pub/Sub Topic
resource "google_pubsub_topic" "operational_dlq" {
  name    = "gov-operational-dlq-${var.environment}"
  project = var.project_id
}

# 3. Security Dead-Letter Queue (SDLQ) Pub/Sub Topic
resource "google_pubsub_topic" "security_dlq" {
  name    = "gov-security-dlq-${var.environment}"
  project = var.project_id
}

# 4. Cloud Tasks Queue for Rate-Limited Asynchronous Processing
resource "google_cloud_tasks_queue" "async_upload_queue" {
  name     = "gov-async-upload-queue-${var.environment}"
  location = var.region
  project  = var.project_id

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 5
  }

  retry_config {
    max_attempts       = 5
    min_backoff        = "5s"
    max_backoff        = "300s"
    max_doublings      = 4
    max_retry_duration = "3600s"
  }
}
