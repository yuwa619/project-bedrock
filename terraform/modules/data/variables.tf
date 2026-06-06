variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS."
  type        = list(string)
}

variable "node_security_group_id" {
  description = "EKS node security group allowed to reach RDS."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for service account trust."
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
