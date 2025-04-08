import functions_framework
import os
from google.cloud import storage
from config.secrets_manager import get_secret
from utils.file_validator import is_valid_file
from utils.gcs_helper import archive_blob

@functions_framework.cloud_event
def ingest_unix_data(cloud_event):
    event_data = cloud_event.data
    bucket_name = event_data["bucket"]
    file_name = event_data["name"]

    if not file_name.endswith(".json"):
        return

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_name)

    if not is_valid_file(blob):
        print("Skipping file <1KB")
        return

    staging_bucket = storage_client.bucket("staging-bucket")
    staging_blob = staging_bucket.blob(file_name)
    staging_blob.copy_from(blob)

    archive_blob(blob, "archive-bucket")
