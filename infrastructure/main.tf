terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.80.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Storage Module
module "storage" {
  source                      = "./modules/storage"
  project_id                  = var.project_id
  region                      = var.region
  environment                 = var.environment
  kms_key_link                = var.kms_key_link
  security_ui_sa_email        = var.security_ui_sa_email
  safeguarding_officers_group = var.safeguarding_officers_group
}

# 2. Database Module
module "database" {
  source     = "./modules/database"
  project_id = var.project_id
  region     = var.region
}

# 3. Async & Queues Module
module "async" {
  source      = "./modules/async"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# 4. APIs & Secrets Module
module "api" {
  source               = "./modules/api"
  project_id           = var.project_id
  region               = var.region
  environment          = var.environment
  security_ui_sa_email = var.security_ui_sa_email
}
