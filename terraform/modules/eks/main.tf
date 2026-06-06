module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.allowed_cluster_public_access_cidrs

  enable_cluster_creator_admin_permissions = false

  access_entries = {
    cluster_creator = {
      principal_arn = var.cluster_admin_principal_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  kms_key_administrators = [
    var.cluster_admin_principal_arn
  ]

  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    bedrock = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      desired_size = 2
      max_size     = 3

      iam_role_additional_policies = {
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      labels = {
        workload = "retail"
      }
    }
  }

  tags = var.tags
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name             = "${var.cluster_name}-vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "vpc-cni"
  service_account_role_arn    = module.vpc_cni_irsa.iam_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = module.ebs_csi_irsa.iam_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    module.eks
  ]

  tags = var.tags
}

module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name                              = "${var.cluster_name}-aws-lbc"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}
