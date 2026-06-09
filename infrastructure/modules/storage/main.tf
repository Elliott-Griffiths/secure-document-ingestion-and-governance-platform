# 1. The Isolated Holding Bucket (Quarantine/Transient Zone)
resource "google_storage_bucket" "holding_bucket" {
  name          = "gov-ingestion-holding-${var.environment}"
  location      = "EUROPE-WEST2" # Data Sovereignty (UK)
  force_destroy = true

  public_access_prevention = "enforced"

  # Failsafe cleanup: stuck files purged after 3 days
  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }

  encryption {
    default_kms_key_name = var.kms_key_link
  }
}

# 2. The Permanent File Store Bucket
resource "google_storage_bucket" "file_store_bucket" {
  name          = "gov-ingestion-filestore-${var.environment}"
  location      = "EUROPE-WEST2" # UK
  force_destroy = false

  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = var.kms_key_link
  }
}

# 3. The Isolated Quarantine Bucket (Evidentiary Preservation)
resource "google_storage_bucket" "quarantine_bucket" {
  name          = "gov-ingestion-quarantine-${var.environment}"
  location      = "EUROPE-WEST2" # UK
  force_destroy = false

  public_access_prevention = "enforced"

  # Evidence preservation: purge after 1 year (365 days)
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  encryption {
    default_kms_key_name = var.kms_key_link
  }
}

# 4. The Security Logs Bucket (Audit Records)
resource "google_storage_bucket" "security_logs_bucket" {
  name          = "gov-ingestion-security-logs-${var.environment}"
  location      = "EUROPE-WEST2" # UK
  force_destroy = false

  public_access_prevention = "enforced"

  # Evidence preservation: purge after 1 year (365 days)
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  encryption {
    default_kms_key_name = var.kms_key_link
  }
}

# 5. Strict IAM for Safeguarding Officers and Security UI on Quarantine Bucket
resource "google_storage_bucket_iam_binding" "quarantine_officer_access" {
  bucket = google_storage_bucket.quarantine_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    var.safeguarding_officers_group,
    "serviceAccount:${var.security_ui_sa_email}"
  ]
}

# 6. Strict IAM for Safeguarding Officers and Security UI on Security Logs Bucket
resource "google_storage_bucket_iam_binding" "security_logs_access" {
  bucket = google_storage_bucket.security_logs_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    var.safeguarding_officers_group,
    "serviceAccount:${var.security_ui_sa_email}"
  ]
}
