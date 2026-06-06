# Verification

Run these checks after `terraform apply`. Capture real output for submission.

## Required Outputs

```sh
cd terraform
terraform output
terraform output -json | jq 'with_entries(select(.key | IN("cluster_endpoint","cluster_name","region","vpc_id","assets_bucket_name")))' > ../grading.json
jq -e '.cluster_endpoint and .cluster_name and .region and .vpc_id and .assets_bucket_name' ../grading.json
```

## AWS Resource Checks

```sh
aws configure get region
aws eks describe-cluster --region us-east-1 --name project-bedrock-cluster --query 'cluster.{name:name,status:status,version:version,endpoint:endpoint}'
aws ec2 describe-vpcs --region us-east-1 --filters Name=tag:Name,Values=project-bedrock-vpc --query 'Vpcs[].VpcId'
aws s3api head-bucket --bucket bedrock-assets-alt-soe-025-3673
aws lambda get-function --region us-east-1 --function-name bedrock-asset-processor --query 'Configuration.FunctionName'
```

Check private RDS:

```sh
aws rds describe-db-instances --region us-east-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `project-bedrock`)].{id:DBInstanceIdentifier,public:PubliclyAccessible,subnets:DBSubnetGroup.Subnets[].SubnetIdentifier}'
```

Check tags:

```sh
aws resourcegroupstaggingapi get-resources --region us-east-1 --tag-filters Key=Project,Values=karatu-2025-capstone --query 'ResourceTagMappingList[].ResourceARN'
```

## Kubernetes Checks

```sh
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster
kubectl get ns retail-app
kubectl get pods -n retail-app -o wide
kubectl get ingress -n retail-app
kubectl get deploy -n kube-system aws-load-balancer-controller
kubectl get secret retail-db-credentials -n retail-app
```

Confirm the UI is reachable:

```sh
ALB_DNS=$(kubectl get ingress -n retail-app -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
curl -I "http://${ALB_DNS}/"
```

Confirm external data services are used:

```sh
kubectl get pods -n retail-app | grep -Ei 'mysql|mariadb|postgres|dynamodb' || true
kubectl logs -n retail-app deploy/catalog --tail=50
kubectl logs -n retail-app deploy/orders --tail=50
kubectl logs -n retail-app deploy/carts --tail=50
```

## Developer IAM User and RBAC

Retrieve credentials safely:

```sh
cd terraform
terraform output -raw developer_access_key_id
terraform output -raw developer_secret_access_key
terraform output -raw developer_console_password
```

Configure a temporary profile for `bedrock-dev-view`, then verify:

```sh
AWS_PROFILE=bedrock-dev-view aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster --alias bedrock-dev-view
kubectl --context bedrock-dev-view get pods -n retail-app
kubectl --context bedrock-dev-view delete pod <pod-name> -n retail-app
```

Expected result: `get pods` works; `delete pod` is forbidden.

## S3 to Lambda

```sh
printf 'test' > /tmp/test.png
aws s3 cp /tmp/test.png s3://bedrock-assets-alt-soe-025-3673/test.png
aws logs tail /aws/lambda/bedrock-asset-processor --region us-east-1 --since 5m
```

Expected log line:

```text
Image received: test.png
```

## CloudWatch Observability

```sh
aws logs describe-log-groups --region us-east-1 --log-group-name-prefix /aws/eks/project-bedrock-cluster/cluster
aws logs describe-log-groups --region us-east-1 --log-group-name-prefix /aws/containerinsights/project-bedrock-cluster
aws logs tail /aws/containerinsights/project-bedrock-cluster/application --region us-east-1 --since 10m
```

## GitHub Actions

```sh
gh pr create --fill
gh run list --workflow "Terraform Plan"
gh run list --workflow "Terraform Apply"
```

Expected result: PRs receive a plan comment; merges to `main` run the apply workflow through the `production` environment gate.

## Secret Hygiene

```sh
git ls-files grading.json
git status --short
git grep -nEi '<tool-attribution-terms>' || true
git grep -nEi '<secret-patterns>' -- ':!docs/verification.md' ':!README.md' || true
```

Expected result: no real access keys, passwords, state files or tool attributions are committed.
