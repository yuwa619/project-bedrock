# Retail Store Helm Deployment

Terraform installs the AWS Retail Store Sample App component charts from `oci://public.ecr.aws/aws-containers` into the `retail-app` namespace.

Components:

- `catalog`: RDS MySQL via `retail-db-credentials`
- `carts`: DynamoDB table `retail-app-carts` via IRSA
- `orders`: RDS PostgreSQL via `retail-db-credentials`; RabbitMQ in-cluster
- `checkout`: Redis in-cluster
- `ui`: ALB Ingress through the AWS Load Balancer Controller

`values-retail-app.yaml` is a Terraform template. It contains endpoints, table names and secret references only; it does not contain passwords.

Manual inspection after apply:

```sh
kubectl get pods -n retail-app
kubectl get ingress -n retail-app
kubectl describe secret retail-db-credentials -n retail-app
```
