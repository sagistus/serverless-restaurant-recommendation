resource "aws_cloudwatch_log_group" "log_group" {
  name              = local.cw_log_group_name
  retention_in_days = var.environment == "prod" ? 14 : 3
  kms_key_id        = aws_kms_key.cmk.arn
  tags              = local.common_tags
  depends_on        = [aws_kms_key.cmk]
}
