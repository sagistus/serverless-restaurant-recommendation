resource "aws_kms_key" "cmk" {
  description             = "CMK for encrypting CloudWatch Logs"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-policy",
    Statement = [
      {
        Sid    = "AllowAccesstoKey",
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "logs.${var.aws_region}.amazonaws.com",
            "secretsmanager.amazonaws.com"
          ]
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

