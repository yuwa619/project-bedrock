terraform {
  backend "s3" {
    bucket       = "bedrock-tfstate-alt-soe-025-3673"
    key          = "project-bedrock/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true

    # Terraform versions below 1.10 do not support S3 native lock files.
    # If an older version is unavoidable, remove use_lockfile and use a
    # DynamoDB lock table configured with dynamodb_table instead.
  }
}
