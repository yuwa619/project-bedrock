resource "aws_s3_bucket" "assets" {
  bucket        = var.bucket_name
  force_destroy = false

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.root}/../lambda/handler.py"
  output_path = "${path.module}/${var.lambda_name}.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.lambda_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_s3_read" {
  name        = "${var.lambda_name}-s3-read"
  description = "Allow the asset processor to read objects from the assets bucket."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_s3_read.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_lambda_function" "asset_processor" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler.handler"
  runtime       = "python3.12"
  filename      = data.archive_file.lambda.output_path

  source_code_hash = data.archive_file.lambda.output_base64sha256

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_s3_read
  ]

  tags = var.tags
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromAssetsBucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets.arn
}

resource "aws_s3_bucket_notification" "assets" {
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}
