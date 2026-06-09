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
