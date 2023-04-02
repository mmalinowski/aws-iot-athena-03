resource "aws_s3_bucket" "etl_scripts_bucket" {
  bucket = "etl-scripts.put-your-fancy-name-here"
}

resource "aws_s3_bucket_acl" "etl_scripts_bucket_acl" {
  bucket = aws_s3_bucket.etl_scripts_bucket.id
  acl    = "private"
}

resource "aws_s3_object" "etl_job_script" {
  key    = "scripts/etl/job.py"
  bucket = aws_s3_bucket.etl_scripts_bucket.id
  source = "resources/job.py"
  etag   = filemd5("resources/job.py")
}

data "aws_iam_policy_document" "etl_job_bucket_policy" {
  statement {
    sid       = "AllowReadScript"
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${aws_s3_bucket.etl_scripts_bucket.arn}", "${aws_s3_bucket.etl_scripts_bucket.arn}/*"]
  }

  statement {
    sid       = "AllowPutData"
    actions   = ["s3:Get*", "s3:List*", "s3:Put*"]
    resources = ["${aws_s3_bucket.cold_bucket.arn}", "${aws_s3_bucket.cold_bucket.arn}/*"]
  }

  statement {
    sid       = "AllowReadRawData"
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${aws_s3_bucket.raw_bucket.arn}", "${aws_s3_bucket.raw_bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "etl_job_role" {
  name               = "meteo-etl-job-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "etl_job_service_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.etl_job_role.name
}

resource "aws_iam_role_policy" "etl_job_cold_bucket_role_allow_s3_read" {
  name   = "allow-s3-bucket-policy"
  role   = aws_iam_role.etl_job_role.name
  policy = data.aws_iam_policy_document.etl_job_bucket_policy.json
}

resource "aws_glue_job" "meteostation_etl_job" {
  name              = "meteostation-etl"
  role_arn          = aws_iam_role.etl_job_role.arn
  timeout           = 60
  number_of_workers = 2
  max_retries       = 1
  worker_type       = "G.1X"
  glue_version      = "4.0"

  command {
    script_location = "s3://${aws_s3_bucket.etl_scripts_bucket.bucket}/${aws_s3_object.etl_job_script.key}"
  }

  default_arguments = {
    "--python_version"      = "3.9"
    "--glue_database"       = aws_glue_catalog_database.meteodata_raw_database.name
    "--glue_table"          = module.meteodata_raw_meteo_station.table_name
    "--cold_storage"        = "s3://${aws_s3_bucket.cold_bucket.bucket}/meteo-station/"
    "--job-bookmark-option" = "job-bookmark-enable"
  }
}
