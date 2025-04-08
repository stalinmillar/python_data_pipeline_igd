from airflow import DAG
from airflow.operators.dummy import DummyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

def trigger_function():
    pass  # Simulate trigger of cloud function

default_args = {"start_date": datetime(2025, 08, 04)}

dag = DAG("retail_ingestion_dag", schedule_interval="@daily", default_args=default_args, catchup=False)

start = DummyOperator(task_id="start", dag=dag)
trigger_ingest = PythonOperator(task_id="trigger_ingest", python_callable=trigger_function, dag=dag)
bq_transform = BigQueryInsertJobOperator(
    task_id="bq_transform",
    configuration={
        "query": {
            "query": """
            INSERT INTO `project_id.finance_raw.retail_macro_master_tb`
            SELECT *,
                CURRENT_TIMESTAMP() AS bq_write_time_timestamp,
                CURRENT_TIMESTAMP() AS update_bq_timestamp,
                TO_JSON_STRING(t) AS raw_payload,
                CURRENT_DATE() AS date_partition_column
            FROM `project_id.finance_raw.retail_macro_staging_tb` t
            """,
            "useLegacySql": False,
        }
    },
    dag=dag
)

end = DummyOperator(task_id="end", dag=dag)

start >> trigger_ingest >> bq_transform >> end
