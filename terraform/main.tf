provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "staging" {
  name     = "${var.project_id}-staging-bucket"
  location = var.region
}

resource "google_storage_bucket" "archive" {
  name     = "${var.project_id}-archive-bucket"
  location = var.region
}

resource "google_bigquery_dataset" "raw" {
  dataset_id = "finance_raw"
  location   = var.region
}

===================Table creation modules
resource "google_bigquery_table" "staging" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  table_id   = "retail_macro_staging_tb"
  schema     = file("/bq/create_staging.json")
}

resource "google_bigquery_table" "master" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  table_id   = "retail_macro_master_tb"
  schema     = file("/bq/create_master.json")
  time_partitioning {
    type  = "DAY"
    field = "date_partition_column"
  }
}

===================Secret modules
resource "google_secret_manager_secret" "sftp_username" {
  secret_id = "sftp_username"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "sftp_password" {
  secret_id = "sftp_password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "sftp_hostname" {
  secret_id = "sftp_hostname"
  replication {
    automatic = true
  }
}
