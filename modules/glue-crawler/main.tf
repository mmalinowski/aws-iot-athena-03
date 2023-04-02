resource "aws_glue_crawler" "location_crawler" {
  name          = "${var.database_name}_${var.table_name}_crawler"
  database_name = var.database_name
  role          = aws_iam_role.glue_crawler_role.arn

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }
  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }

  s3_target {
    path = "s3://${var.bucket.id}/${var.directory}"
  }
}
