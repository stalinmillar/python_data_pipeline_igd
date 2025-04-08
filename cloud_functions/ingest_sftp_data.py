import functions_framework
import paramiko
from google.cloud import storage
from config.secrets_manager import get_secret

@functions_framework.http
def ingest_sftp_data(request):
    hostname = get_secret("sftp_hostname")
    username = get_secret("sftp_username")
    password = get_secret("sftp_password")

    sftp_path = "/path/to/monthly_data.json"

    transport = paramiko.Transport((hostname, 22))
    transport.connect(username=username, password=password)
    sftp = paramiko.SFTPClient.from_transport(transport)

    with sftp.file(sftp_path, 'r') as file:
        data = file.read()
        if len(data) < 1024:
            return "File too small"

        storage_client = storage.Client()
        bucket = storage_client.bucket("staging-bucket")
        blob = bucket.blob(os.path.basename(sftp_path))
        blob.upload_from_string(data)

    sftp.close()
    transport.close()
    return "SFTP file ingested"
