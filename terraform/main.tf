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

resource "google_bigquery_routine" "load_to_master" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  routine_id = "load_to_master"
  routine_type = "PROCEDURE"

  definition_body = <<EOT
  BEGIN
    INSERT INTO `project_id.finance_raw.retail_macro_master_tb`
    SELECT *,
      CURRENT_TIMESTAMP() AS bq_write_time_timestamp,
      CURRENT_TIMESTAMP() AS update_bq_timestamp,
      TO_JSON_STRING(t) AS raw_payload,
      CURRENT_DATE() AS date_partition_column
    FROM `project_id.finance_raw.retail_macro_staging_tb` t;
  END;
  EOT
}

resource "google_bigquery_data_transfer_config" "scheduled_query" {
  display_name           = "Scheduled Load to Master"
  data_source_id         = "scheduled_query"
  destination_dataset_id = google_bigquery_dataset.raw.dataset_id
  params = {
    query = <<EOT
      CALL `project_id.finance_raw.load_to_master`();
    EOT
    destination_table_name_template = "ignore"
    write_disposition               = "WRITE_APPEND"
  }
  schedule               = "every 24 hours"
  location               = var.region
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
