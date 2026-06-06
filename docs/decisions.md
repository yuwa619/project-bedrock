# Decisions

Student ID: `ALT/SOE/025/3673`

## EKS Version

The cluster is pinned to Kubernetes `1.34` as required. The EKS Terraform module is pinned to `terraform-aws-modules/eks/aws` `~> 21.0`, and the AWS provider is constrained to `>= 5.70, < 7.0`. If `terraform plan` rejects version `1.34`, the module or provider should be upgraded rather than downgrading the cluster.

## Managed Node Groups

Managed node groups were chosen because they are predictable for grading, integrate cleanly with the AWS Load Balancer Controller and CloudWatch Observability add-on, and avoid the extra operational work of self-managed workers. The node group uses two `t3.large` on-demand nodes to provide enough pod and ENI headroom for the retail services and system add-ons.

## Single NAT Gateway

The VPC uses one NAT Gateway. Private nodes need egress for image pulls, AWS API calls and logging, but one NAT Gateway keeps costs lower than one per AZ. The trade-off is reduced AZ-level egress resilience, which is acceptable for this capstone and documented in the cost warning.

## Lowercase S3 Bucket Name

The brief states `bedrock-assets-[student-id]`. Because S3 bucket names must be lowercase and cannot include slashes, the assets bucket is `bedrock-assets-alt-soe-025-3673`. This keeps the required stem while obeying AWS naming rules.

## Terraform-Managed Kubernetes Secrets

Terraform creates database passwords, stores them in Secrets Manager, and also writes them to a Kubernetes Secret named `retail-db-credentials` in `retail-app`. This keeps credentials out of committed files and makes the deployment reproducible for grading. The trade-off is that Terraform state contains sensitive values, so state must stay in the encrypted S3 backend and must not be committed.

## GitHub OIDC

GitHub Actions uses OIDC to assume `project-bedrock-gha` instead of storing long-lived AWS keys. The trust policy is scoped to the configured GitHub repository, PR events and the `main` branch. The CI role uses `AdministratorAccess` because Terraform manages IAM, EKS, VPC, RDS, S3, Lambda and Kubernetes integrations; this is a broad capstone trade-off protected by repository-scoped OIDC and a production environment gate.

## Retail App Data Choices

- Catalog uses private RDS MySQL.
- Orders uses private RDS PostgreSQL.
- Carts uses DynamoDB through an IRSA role scoped to the carts table.
- Redis and RabbitMQ stay in-cluster to keep the managed-service footprint and cost reasonable.

## Known Grading Risks

- The assets bucket is lowercase by AWS necessity; the README and this file call out the deviation.
- EKS API readiness can lag cluster creation. If a first apply fails while installing Kubernetes or Helm resources, rerun `terraform apply`.
- The GitHub OIDC role must exist before GitHub Actions can assume it, so the first deployment is local.
- The GitHub repository value in `terraform.tfvars` must match the actual repository or Actions authentication will fail.
- CI rejects plans containing delete actions. Intentional replacements should be applied manually after review.
