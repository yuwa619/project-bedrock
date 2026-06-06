module "network" {
  source = "./modules/network"

  name         = local.vpc_name
  cluster_name = local.cluster_name
  tags         = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name                        = local.cluster_name
  cluster_version                     = "1.34"
  vpc_id                              = module.network.vpc_id
  private_subnet_ids                  = module.network.private_subnet_ids
  allowed_cluster_public_access_cidrs = var.allowed_cluster_public_access_cidrs
  node_instance_types                 = var.node_instance_types
  tags                                = local.common_tags
}

module "data" {
  source = "./modules/data"

  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  node_security_group_id  = module.eks.node_security_group_id
  namespace               = local.namespace
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn
  tags                    = local.common_tags
}

module "assets" {
  source = "./modules/assets"

  bucket_name = local.assets_bucket_name
  lambda_name = local.lambda_name
  tags        = local.common_tags
}

resource "kubernetes_namespace_v1" "retail_app" {
  metadata {
    name = local.namespace

    labels = {
      Project = local.required_project
    }
  }

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_secret_v1" "retail_db_credentials" {
  metadata {
    name      = "retail-db-credentials"
    namespace = kubernetes_namespace_v1.retail_app.metadata[0].name

    labels = {
      Project = local.required_project
    }
  }

  data = {
    RETAIL_CATALOG_PERSISTENCE_USER     = module.data.catalog_db_username
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = module.data.catalog_db_password
    RETAIL_ORDERS_PERSISTENCE_USERNAME  = module.data.orders_db_username
    RETAIL_ORDERS_PERSISTENCE_PASSWORD  = module.data.orders_db_password

    CATALOG_DB_HOST = module.data.catalog_db_host
    CATALOG_DB_PORT = tostring(module.data.catalog_db_port)
    CATALOG_DB_NAME = module.data.catalog_db_name
    ORDERS_DB_HOST  = module.data.orders_db_host
    ORDERS_DB_PORT  = tostring(module.data.orders_db_port)
    ORDERS_DB_NAME  = module.data.orders_db_name
    CARTS_TABLE     = module.data.carts_table_name
  }

  type = "Opaque"
}

module "iam_developer" {
  source = "./modules/iam-developer"

  user_name               = local.developer_user_name
  assets_bucket_arn       = module.assets.bucket_arn
  cluster_name            = module.eks.cluster_name
  namespace               = kubernetes_namespace_v1.retail_app.metadata[0].name
  console_password_length = var.developer_console_password_length
  tags                    = local.common_tags

  depends_on = [
    kubernetes_namespace_v1.retail_app
  ]
}

module "cicd_oidc" {
  source = "./modules/cicd-oidc"

  github_repo  = var.github_repo
  cluster_name = module.eks.cluster_name
  tags         = local.common_tags
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  wait    = true
  timeout = 900

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      region      = var.region
      vpcId       = module.network.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.eks.load_balancer_controller_role_arn
        }
      }
    })
  ]

  depends_on = [
    module.eks
  ]
}

locals {
  retail_values = yamldecode(templatefile("${path.root}/../helm/values-retail-app.yaml", {
    catalog_db_host                = module.data.catalog_db_host
    catalog_db_port                = module.data.catalog_db_port
    catalog_db_name                = module.data.catalog_db_name
    orders_db_host                 = module.data.orders_db_host
    orders_db_port                 = module.data.orders_db_port
    orders_db_name                 = module.data.orders_db_name
    carts_table_name               = module.data.carts_table_name
    carts_service_account_role_arn = module.data.carts_service_account_role_arn
  }))
}

resource "helm_release" "catalog" {
  count = var.enable_retail_helm_release ? 1 : 0

  name       = "catalog"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-catalog-chart"
  version    = var.retail_chart_version
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  values = [yamlencode(local.retail_values.catalog)]

  wait    = true
  timeout = 900

  depends_on = [
    kubernetes_secret_v1.retail_db_credentials
  ]
}

resource "helm_release" "carts" {
  count = var.enable_retail_helm_release ? 1 : 0

  name       = "carts"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-cart-chart"
  version    = var.retail_chart_version
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  values = [yamlencode(local.retail_values.carts)]

  wait    = true
  timeout = 900

  depends_on = [
    kubernetes_secret_v1.retail_db_credentials
  ]
}

resource "helm_release" "orders" {
  count = var.enable_retail_helm_release ? 1 : 0

  name       = "orders"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-orders-chart"
  version    = var.retail_chart_version
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  values = [yamlencode(local.retail_values.orders)]

  wait    = true
  timeout = 900

  depends_on = [
    kubernetes_secret_v1.retail_db_credentials
  ]
}

resource "helm_release" "checkout" {
  count = var.enable_retail_helm_release ? 1 : 0

  name       = "checkout"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-checkout-chart"
  version    = var.retail_chart_version
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  values = [yamlencode(local.retail_values.checkout)]

  wait    = true
  timeout = 900

  depends_on = [
    helm_release.orders
  ]
}

resource "helm_release" "ui" {
  count = var.enable_retail_helm_release ? 1 : 0

  name       = "ui"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-ui-chart"
  version    = var.retail_chart_version
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  values = [yamlencode(local.retail_values.ui)]

  wait    = true
  timeout = 900

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.catalog,
    helm_release.carts,
    helm_release.checkout,
    helm_release.orders
  ]
}
