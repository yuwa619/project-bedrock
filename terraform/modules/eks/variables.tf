variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the cluster and nodes."
  type        = list(string)
}

variable "allowed_cluster_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Managed node group instance types."
  type        = list(string)
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
