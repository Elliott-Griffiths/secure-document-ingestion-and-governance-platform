variable "project_id" {
  type        = string
  description = "The GCP Project ID."
}

variable "region" {
  type        = string
  description = "The GCP target region."
}

variable "environment" {
  type        = string
  description = "The target environment (e.g., dev, staging, prod)."
}

variable "kms_key_link" {
  type        = string
  description = "The KMS key link for bucket encryption."
}

variable "security_ui_sa_email" {
  type        = string
  description = "The Security UI Service Account email."
}

variable "safeguarding_officers_group" {
  type        = string
  description = "The group address for Safeguarding Officers."
}
