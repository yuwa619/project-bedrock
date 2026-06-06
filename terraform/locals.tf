locals {
  project_name        = "project-bedrock"
  student_id          = "ALT/SOE/025/3673"
  required_project    = "karatu-2025-capstone"
  cluster_name        = "project-bedrock-cluster"
  vpc_name            = "project-bedrock-vpc"
  namespace           = "retail-app"
  assets_bucket_name  = "bedrock-assets-alt-soe-025-3673"
  developer_user_name = "bedrock-dev-view"
  lambda_name         = "bedrock-asset-processor"

  common_tags = {
    Project   = local.required_project
    ManagedBy = "terraform"
    StudentID = local.student_id
  }
}
