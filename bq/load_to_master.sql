INSERT INTO `project_id.finance_raw.retail_macro_master_tb`
SELECT *,
    CURRENT_TIMESTAMP() AS bq_write_time_timestamp,
    CURRENT_TIMESTAMP() AS update_bq_timestamp,
    TO_JSON_STRING(t) AS raw_payload,
    CURRENT_DATE() AS date_partition_column
FROM `project_id.finance_raw.retail_macro_staging_tb` t;
