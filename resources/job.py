import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import types as t
from pyspark.sql.functions import when, to_date


def dataframe_from_catalog(ctx, database, table):
    dynamic_frame = ctx.create_dynamic_frame.from_catalog(
        database=database,
        table_name=table,
        transformation_ctx="meteo_data_etl_ctx")
    return dynamic_frame.toDF()


def add_temperature_column(meteostation_df):
    return meteostation_df.withColumn(
        "temperature",
        when(meteostation_df.values[0].unit == 'F',
             f_to_c(meteostation_df.values[0].value)).otherwise(
                 meteostation_df.values[0].value))


def add_pressure_column(meteostation_df):
    return meteostation_df.withColumn(
        "atm",
        when(meteostation_df.values[1].unit == 'mmHg',
             mmhg_to_kPa(meteostation_df.values[1].value)).otherwise(
                 mbar_to_kPa(meteostation_df.values[1].value)))


def add_humidity_column(meteostation_df):
    return meteostation_df.withColumn("humidity",
                                      meteostation_df.values[2].value)


def add_date_column(meteostation_df):
    return meteostation_df.withColumn(
        "date",
        to_date((meteostation_df.timestamp /
                 1000).cast(dataType=t.TimestampType())))


args = getResolvedOptions(
    sys.argv, ['JOB_NAME', 'glue_database', 'glue_table', 'cold_storage'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print("Starting ETL job")

f_to_c = lambda x: (x - 32) * 5 / 9
mmhg_to_kPa = lambda x: x * 0.133322
mbar_to_kPa = lambda x: x * 0.1

meteostation_df = dataframe_from_catalog(glueContext, args["glue_database"],
                                         args["glue_table"])

if len(meteostation_df.take(1)) != 0:
    meteostation_df = meteostation_df.drop("date")
    meteostation_df = meteostation_df.drop("deviceid")
    meteostation_df = add_temperature_column(meteostation_df)
    meteostation_df = add_pressure_column(meteostation_df)
    meteostation_df = add_humidity_column(meteostation_df)
    meteostation_df = add_date_column(meteostation_df)
    meteostation_df = meteostation_df.drop("values")

    meteostation_df.show()

    meteostation_df.repartition(1).write.option(
        "compression", "snappy").option("maxRecordsPerFile", 50).partitionBy(
            "device_id", "date").mode("append").parquet(args["cold_storage"])
else:
    print("No data to process")

print("All done!")

job.commit()