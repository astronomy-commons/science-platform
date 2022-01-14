# Populate the metastore database with data from S3
from pyspark.sql import SparkSession
import axs
import os

spark = SparkSession.builder.config(
    "spark.master", "local[*]"
).enableHiveSupport().getOrCreate()
catalog = axs.AxsCatalog(spark)

table_names = catalog.list_table_names()

table_name_to_bucket_path = {
    "ztf": "s3a://axscatalog/ztf_dr3_public",
    "allwise": "s3a://axscatalog/allwise",
    "gaiadr2": "s3a://axscatalog/gaiadr2",
    "ps1": "s3a://axscatalog/ps1",
    "sdss": "s3a://axscatalog/sdss"
}

for table_name, bucket_path in table_name_to_bucket_path.items():
    if table_name not in table_names:
        catalog.import_existing_table(
            table_name,
            bucket_path,
            num_buckets=500, 
            zone_height=axs.Constants.ONE_AMIN,
            import_into_spark=True
        )

        table = catalog.load(table_name)
        try:
            table.head(1)
        except Exception as e:
            print(f"Exception getting data from table {table_name} at path {bucket_path}: {e}")