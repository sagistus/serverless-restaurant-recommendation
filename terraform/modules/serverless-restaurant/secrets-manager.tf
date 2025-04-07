resource "aws_secretsmanager_secret" "db_secret" {
  name       = local.secret_name
  kms_key_id = aws_kms_key.cmk.arn
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
    username = var.db_user
    password = var.db_password
  })
}
