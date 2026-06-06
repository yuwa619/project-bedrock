output "user_arn" {
  value = aws_iam_user.developer.arn
}

output "access_key_id" {
  value     = aws_iam_access_key.developer.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.developer.secret
  sensitive = true
}

output "console_password" {
  value     = aws_iam_user_login_profile.developer.password
  sensitive = true
}

output "kubernetes_group" {
  value = local.kubernetes_group
}
