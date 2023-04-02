data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_crawler_role" {
  name               = "glue-crawler-${var.database_name}-${var.table_name}-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "glue_service_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  role       = aws_iam_role.glue_crawler_role.name
}

data "aws_iam_policy_document" "glue_read_source_bucket_policy" {
  statement {
    sid       = "AllowReadData"
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${var.bucket.arn}/${var.directory}", "${var.bucket.arn}/${var.directory}/*"]
  }
}

resource "aws_iam_role_policy" "glue_crawler_role_allow_source_read" {
  name   = "allow-source-read"
  role   = aws_iam_role.glue_crawler_role.name
  policy = data.aws_iam_policy_document.glue_read_source_bucket_policy.json
}
