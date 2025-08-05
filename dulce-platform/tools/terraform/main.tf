# Main Terraform configuration for Google Cloud resources

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Variables
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "asia-southeast1" # Vietnam/Singapore region for lower latency
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

# Resource Group - this will be a resource container for all created resources
resource "google_project_service" "required_services" {
  for_each = toset([
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudfunctions.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Storage bucket for artifacts
resource "google_storage_bucket" "artifacts" {
  name     = "${var.project_id}-artifacts"
  location = var.region
  force_destroy = true
  uniform_bucket_level_access = true
  
  depends_on = [
    google_project_service.required_services
  ]
}

# BigQuery dataset
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "analytics"
  friendly_name               = "Analytics Dataset"
  description                 = "Dataset for F&B analytics data"
  location                    = var.region
  default_table_expiration_ms = 3600000 * 24 * 30 # 30 days
  
  depends_on = [
    google_project_service.required_services
  ]
  
  labels = {
    env = var.environment
  }
  
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "operational_db" {
  name             = "dulce-operational-db-${var.environment}"
  database_version = "POSTGRES_14"
  region           = var.region
  
  depends_on = [
    google_project_service.required_services
  ]
  
  settings {
    tier = var.environment == "production" ? "db-custom-2-7680" : "db-f1-micro"
    
    backup_configuration {
      enabled            = true
      binary_log_enabled = false
      start_time         = "00:00"
    }
    
    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
    
    maintenance_window {
      day          = 7  # Sunday
      hour         = 2  # 2 AM
      update_track = "stable"
    }
  }
  
  deletion_protection = var.environment == "production" ? true : false
}

# Cloud SQL Database
resource "google_sql_database" "operational_db" {
  name     = "dulce_operations"
  instance = google_sql_database_instance.operational_db.name
}

# Pub/Sub topic for data ingestion
resource "google_pubsub_topic" "data_ingestion" {
  name = "data-ingestion-${var.environment}"
  
  depends_on = [
    google_project_service.required_services
  ]
  
  labels = {
    env = var.environment
  }
}

# Service Account for agents
resource "google_service_account" "agent_service_account" {
  account_id   = "dulce-agents-${var.environment}"
  display_name = "Dulce Agents Service Account"
  
  depends_on = [
    google_project_service.required_services
  ]
}

# IAM roles for service account
resource "google_project_iam_member" "agent_bigquery_access" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.agent_service_account.email}"
}

resource "google_project_iam_member" "agent_pubsub_access" {
  project = var.project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.agent_service_account.email}"
}

resource "google_project_iam_member" "agent_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.agent_service_account.email}"
}

# Output values
output "operational_db_connection_name" {
  value = google_sql_database_instance.operational_db.connection_name
  description = "Cloud SQL instance connection name"
}

output "pubsub_topic" {
  value = google_pubsub_topic.data_ingestion.name
  description = "Pub/Sub topic for data ingestion"
}

output "agent_service_account_email" {
  value = google_service_account.agent_service_account.email
  description = "Service account email for agents"
}
