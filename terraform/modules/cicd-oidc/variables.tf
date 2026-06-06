variable "github_repo" {
  description = "GitHub repository in owner/name format."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
}
