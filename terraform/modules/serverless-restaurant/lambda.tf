data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function_payload.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "restuarant_finder_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_access_policy" {
  name = "LambdaAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = aws_secretsmanager_secret.db_secret.arn
      },
      {
        Effect   = "Allow",
        Action   = ["kms:Encrypt", "kms:Decrypt"],
        Resource = aws_kms_key.cmk.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_access_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_access_policy.arn
}
resource "aws_iam_role_policy_attachment" "lambda_execution_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "restaurant_lambda" {
  function_name    = "restaurantRecommendationFunction"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      RESTAURANT_STYLES   = local.restaurant_styles
      VEGETARIAN_KEYWORDS = local.vegetarian_keywords
      DELIVERY_KEYWORDS   = local.delivery_keywords
      DB_SECRET_ARN       = aws_secretsmanager_secret.db_secret.arn

    }
  }
  depends_on = [data.archive_file.lambda_zip]
}

