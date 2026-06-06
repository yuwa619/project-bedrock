variable "bucket_name" {
  description = "S3 bucket name for assets."
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
