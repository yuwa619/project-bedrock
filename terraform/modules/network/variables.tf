variable "name" {
  description = "VPC name."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet tags."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
