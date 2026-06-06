locals {
  kubernetes_group = "dev-viewers"
}

resource "aws_iam_user" "developer" {
  name          = var.user_name
  force_destroy = true

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "assets_put_object" {
  name        = "${var.user_name}-assets-put-object"
  description = "Allow bedrock-dev-view to upload objects only to the Project Bedrock assets bucket."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.assets_bucket_arn}/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "assets_put_object" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.assets_put_object.arn
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

resource "aws_iam_user_login_profile" "developer" {
  user                    = aws_iam_user.developer.name
  password_length         = var.console_password_length
  password_reset_required = true
}

resource "aws_eks_access_entry" "developer" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_user.developer.arn
  kubernetes_groups = [local.kubernetes_group]
  type              = "STANDARD"

  tags = var.tags
}

resource "kubernetes_role_v1" "pod_viewer" {
  metadata {
    name      = "pod-viewer"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "developer_pod_viewer" {
  metadata {
    name      = "${var.user_name}-pod-viewer"
    namespace = var.namespace
  }

  subject {
    kind      = "Group"
    name      = local.kubernetes_group
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role_v1.pod_viewer.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
