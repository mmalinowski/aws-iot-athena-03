resource "aws_glue_catalog_database" "meteodata_cold_database" {
  name = "meteodata_cold"
}

module "meteodata_cold_meteo_station" {
  source = "./modules/glue-crawler"

  database_name = aws_glue_catalog_database.meteodata_cold_database.name
  table_name    = "meteo_station"
  bucket        = aws_s3_bucket.cold_bucket
  directory     = "meteo-station"
}

resource "aws_glue_catalog_table" "meteodata_cold_meteo_station_table" {
  name          = module.meteodata_cold_meteo_station.table_name
  database_name = aws_glue_catalog_database.meteodata_cold_database.name
  table_type    = "EXTERNAL_TABLE"

  partition_keys {
    name = "device_id"
    type = "string"
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  parameters = {
    "classification"  = "parquet"
    "compressionType" = "snappy"
    "typeOfData"      = "file"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cold_bucket.bucket}/meteo-station/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" : 1,
      }
    }

    parameters = {
      "classification"              = "parquet"
      "compressionType"             = "snappy"
      "typeOfData"                  = "file"
      EXTERNAL                      = "TRUE",
      "partition_filtering.enabled" = "true"
    }

    columns {
      name = "timestamp"
      type = "bigint"
    }

    columns {
      name = "temperature"
      type = "double"
    }

    columns {
      name = "atm"
      type = "double"
    }

    columns {
      name = "humidity"
      type = "int"
    }
  }
}

resource "aws_glue_partition_index" "meteodata_cold_meteo_station_table_idx" {
  database_name = aws_glue_catalog_database.meteodata_cold_database.name
  table_name    = module.meteodata_cold_meteo_station.table_name

  partition_index {
    index_name = "device_id_date_idx"
    keys       = ["device_id", "date"]
  }
}
