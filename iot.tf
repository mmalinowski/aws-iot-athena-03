locals {
  things = ["meteo-001", "meteo-002"]
}

resource "aws_s3_bucket" "raw_bucket" {
  bucket = "iot.raw.put-your-fancy-name-here"
}

resource "aws_s3_bucket_acl" "raw_bucket_acl" {
  bucket = aws_s3_bucket.raw_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket" "cold_bucket" {
  bucket = "iot.cold.put-your-fancy-name-here"
}

resource "aws_s3_bucket_acl" "cold_bucket_acl" {
  bucket = aws_s3_bucket.cold_bucket.id
  acl    = "private"
}

resource "aws_iot_thing_group" "meteo_stations_group" {
  name = "meteo-station"
}

module "thing" {
  for_each     = toset(local.things)
  source       = "./modules/thing"
  thing_group  = aws_iot_thing_group.meteo_stations_group.name
  thing_id     = each.key
  outputs_path = "./cert"
}

data "aws_iam_policy_document" "iot_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iot_write_to_raw_bucket_policy" {
  statement {
    sid       = "AllowPutObject"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.raw_bucket.arn}/*"]
  }
}

resource "aws_iam_role" "iot_raw_bucket_write_role" {
  name               = "iot-raw-bucket-write-role"
  assume_role_policy = data.aws_iam_policy_document.iot_assume_role_policy.json
}

resource "aws_iam_role_policy" "iot_raw_bucket_write_role_allow_s3_put" {
  name   = "allow-s3-raw-bucket-put"
  role   = aws_iam_role.iot_raw_bucket_write_role.name
  policy = data.aws_iam_policy_document.iot_write_to_raw_bucket_policy.json
}

resource "aws_iot_topic_rule" "raw_bucket_rule" {
  name        = "raw_bucket_rule"
  description = "A rule to store raw payload in S3 bucket"
  enabled     = true
  sql         = "SELECT * FROM 'devices/${aws_iot_thing_group.meteo_stations_group.name}/+'"
  sql_version = "2016-03-23"

  s3 {
    bucket_name = aws_s3_bucket.raw_bucket.id
    role_arn    = aws_iam_role.iot_raw_bucket_write_role.arn
    key         = "$${topic(2)}/$${topic(3)}/$${parse_time(\"yyyy-MM-dd\", timestamp())}/$${timestamp()}.json"
  }
}
