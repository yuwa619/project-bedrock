# Architecture

![Project Bedrock architecture](project-bedrock.png)

The diagram shows:

- AWS account boundary in `us-east-1`
- VPC `project-bedrock-vpc` with CIDR `10.0.0.0/16`
- Two availability zones with public and private subnets
- Internet Gateway, single NAT Gateway and an internet-facing ALB
- EKS cluster `project-bedrock-cluster` with managed nodes in private subnets
- `retail-app` namespace running UI, catalog, carts, checkout and orders
- RDS MySQL for catalog, RDS PostgreSQL for orders and DynamoDB for carts
- In-cluster Redis and RabbitMQ
- Secrets Manager and Kubernetes Secret `retail-db-credentials`
- Private S3 bucket `bedrock-assets-alt-soe-025-3673`
- Lambda `bedrock-asset-processor` triggered by S3 `ObjectCreated`
- CloudWatch control plane, container and Lambda logs
- IAM user `bedrock-dev-view` and GitHub OIDC role `project-bedrock-gha`
