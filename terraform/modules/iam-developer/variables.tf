variable "user_name" {
  description = "Developer IAM user name."
  type        = string
}

variable "assets_bucket_arn" {
  description = "Assets bucket ARN."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for RBAC."
  type        = string
}

variable "console_password_length" {
  description = "Generated console password length."
  type        = number
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
