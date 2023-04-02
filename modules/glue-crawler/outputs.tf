output "table_name" {
  value = var.table_name
}

output "s3_location" {
  value = "s3://${var.bucket.id}/${var.directory}/"
}
