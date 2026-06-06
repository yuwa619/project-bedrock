locals {
  catalog_db_name     = "catalog"
  catalog_db_username = "catalog_admin"
  orders_db_name      = "orders"
  orders_db_username  = "orders_admin"
  carts_table_name    = "retail-app-carts"
  oidc_host_path      = replace(var.cluster_oidc_issuer_url, "https://", "")
}

resource "random_password" "catalog" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "orders" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "mysql" {
  name        = "project-bedrock-mysql"
  description = "Allow MySQL from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "project-bedrock-mysql"
  })
}

resource "aws_security_group" "postgres" {
  name        = "project-bedrock-postgres"
  description = "Allow PostgreSQL from EKS nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "project-bedrock-postgres"
  })
}

module "mysql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.12"

  identifier = "project-bedrock-mysql"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 40
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = local.catalog_db_name
  username = local.catalog_db_username
  password = random_password.catalog.result
  port     = 3306

  manage_master_user_password = false

  create_db_subnet_group = true
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.mysql.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  performance_insights_enabled = false

  tags = var.tags
}

module "postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.12"

  identifier = "project-bedrock-postgres"

  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 40
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = local.orders_db_name
  username = local.orders_db_username
  password = random_password.orders.result
  port     = 5432

  manage_master_user_password = false

  create_db_subnet_group = true
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  performance_insights_enabled = false

  tags = var.tags
}

resource "aws_dynamodb_table" "carts" {
  name         = local.carts_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = local.carts_table_name
  })
}

resource "aws_secretsmanager_secret" "catalog" {
  name                    = "project-bedrock/catalog-db"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "project-bedrock/catalog-db"
  })
}

resource "aws_secretsmanager_secret_version" "catalog" {
  secret_id = aws_secretsmanager_secret.catalog.id

  secret_string = jsonencode({
    username = local.catalog_db_username
    password = random_password.catalog.result
    host     = module.mysql.db_instance_address
    port     = module.mysql.db_instance_port
    dbname   = local.catalog_db_name
  })
}

resource "aws_secretsmanager_secret" "orders" {
  name                    = "project-bedrock/orders-db"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "project-bedrock/orders-db"
  })
}

resource "aws_secretsmanager_secret_version" "orders" {
  secret_id = aws_secretsmanager_secret.orders.id

  secret_string = jsonencode({
    username = local.orders_db_username
    password = random_password.orders.result
    host     = module.postgres.db_instance_address
    port     = module.postgres.db_instance_port
    dbname   = local.orders_db_name
  })
}

data "aws_iam_policy_document" "carts_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host_path}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host_path}:sub"
      values   = ["system:serviceaccount:${var.namespace}:carts"]
    }
  }
}

resource "aws_iam_role" "carts_dynamodb" {
  name               = "project-bedrock-carts-dynamodb"
  assume_role_policy = data.aws_iam_policy_document.carts_assume_role.json

  tags = var.tags
}

resource "aws_iam_policy" "carts_dynamodb" {
  name        = "project-bedrock-carts-dynamodb"
  description = "Allow carts service to use the retail app DynamoDB table."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = [
          aws_dynamodb_table.carts.arn,
          "${aws_dynamodb_table.carts.arn}/index/*"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "carts_dynamodb" {
  role       = aws_iam_role.carts_dynamodb.name
  policy_arn = aws_iam_policy.carts_dynamodb.arn
}
