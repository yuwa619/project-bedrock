output "catalog_db_host" {
  value = module.mysql.db_instance_address
}

output "catalog_db_port" {
  value = module.mysql.db_instance_port
}

output "catalog_db_name" {
  value = local.catalog_db_name
}

output "catalog_db_username" {
  value = local.catalog_db_username
}

output "catalog_db_password" {
  value     = random_password.catalog.result
  sensitive = true
}

output "orders_db_host" {
  value = module.postgres.db_instance_address
}

output "orders_db_port" {
  value = module.postgres.db_instance_port
}

output "orders_db_name" {
  value = local.orders_db_name
}

output "orders_db_username" {
  value = local.orders_db_username
}

output "orders_db_password" {
  value     = random_password.orders.result
  sensitive = true
}

output "carts_table_name" {
  value = aws_dynamodb_table.carts.name
}

output "carts_service_account_role_arn" {
  value = aws_iam_role.carts_dynamodb.arn
}

output "mysql_security_group_id" {
  value = aws_security_group.mysql.id
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres.id
}
