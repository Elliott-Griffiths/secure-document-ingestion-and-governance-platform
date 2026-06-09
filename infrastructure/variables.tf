variable "project_id" {
  type        = string
  description = "The Google Cloud Platform Project ID."
}

variable "region" {
  type        = string
  default     = "europe-west2"
  description = "The target region for GCP resources, pinned to UK (europe-west2) for data sovereignty."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "The target environment (e.g., dev, staging, prod)."
}

variable "kms_key_link" {
  type        = string
  description = "The fully qualified resource link of the KMS key to use for encrypting buckets and tables."
}

variable "security_ui_sa_email" {
  type        = string
  description = "The service account email address used by the Security UI service."
}

variable "safeguarding_officers_group" {
  type        = string
  default     = "group:safeguarding-officers@council.gov.uk"
  description = "The identity identifier for the safeguarding officers who require access to quarantined evidence."
}
