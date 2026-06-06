output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS Region."
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "assets_bucket_name" {
  description = "Private S3 assets bucket name."
  value       = module.assets.bucket_name
}

output "developer_access_key_id" {
  description = "Access key ID for bedrock-dev-view."
  value       = module.iam_developer.access_key_id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret access key for bedrock-dev-view."
  value       = module.iam_developer.secret_access_key
  sensitive   = true
}

output "developer_console_password" {
  description = "Generated console password for bedrock-dev-view."
  value       = module.iam_developer.console_password
  sensitive   = true
}

output "github_actions_role_arn" {
  description = "IAM role ARN used by GitHub Actions OIDC."
  value       = module.cicd_oidc.role_arn
}

output "retail_app_namespace" {
  description = "Kubernetes namespace for the retail app."
  value       = kubernetes_namespace_v1.retail_app.metadata[0].name
}
