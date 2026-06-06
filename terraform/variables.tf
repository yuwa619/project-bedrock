variable "region" {
  description = "AWS Region for Project Bedrock."
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repository in owner/name format for the Actions OIDC trust policy."
  type        = string
  default     = "Yuwa/project-bedrock"
}

variable "allowed_cluster_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "developer_console_password_length" {
  description = "Length of the generated IAM console password for bedrock-dev-view."
  type        = number
  default     = 24
}

variable "retail_chart_version" {
  description = "AWS Retail Store Sample App chart version."
  type        = string
  default     = "1.6.1"
}

variable "enable_retail_helm_release" {
  description = "Install the retail app Helm releases from Terraform after the EKS cluster is reachable."
  type        = bool
  default     = true
}
