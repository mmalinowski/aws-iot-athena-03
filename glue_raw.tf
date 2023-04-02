resource "aws_glue_catalog_database" "meteodata_raw_database" {
  name = "meteodata_raw"
}

module "meteodata_raw_meteo_station" {
  source = "./modules/glue-crawler"

  database_name = aws_glue_catalog_database.meteodata_raw_database.name
  table_name    = "meteo_station"
  bucket        = aws_s3_bucket.raw_bucket
  directory     = "meteo-station"
}

resource "aws_glue_catalog_table" "meteodata_raw_meteo_station_table" {
  name          = module.meteodata_raw_meteo_station.table_name
  database_name = aws_glue_catalog_database.meteodata_raw_database.name
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
    "classification"              = "json"
    "compressionType"             = "none"
    "typeOfData"                  = "file"
    "partition_filtering.enabled" = "true"
  }

  storage_descriptor {
    location      = module.meteodata_raw_meteo_station.s3_location
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    parameters = {
      "classification"  = "json"
      "compressionType" = "none"
      "typeOfData"      = "file"
    }

    columns {
      name = "deviceid"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "bigint"
    }

    columns {
      name = "values"
      type = "array<struct<name:string,unit:string,value:int>>"
    }
  }
}

resource "aws_glue_partition_index" "meteodata_raw_meteo_station_table_idx" {
  database_name = aws_glue_catalog_database.meteodata_raw_database.name
  table_name    = module.meteodata_raw_meteo_station.table_name

  partition_index {
    index_name = "device_id_date_idx"
    keys       = ["device_id", "date"]
  }
}
