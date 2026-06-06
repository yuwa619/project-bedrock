output "bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.assets.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.asset_processor.function_name
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}
