variable "database_name" {
  description = "Glue catalog database name"
  type        = string
}

variable "table_name" {
  description = "Glue catalog table name"
  type        = string
}

variable "bucket" {
  description = "Bucket to be crawled"
}

variable "directory" {
  description = "location in S3 backet to crawl data from"
  type        = string
}

