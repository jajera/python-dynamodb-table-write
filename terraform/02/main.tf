locals {
  suffix = data.terraform_remote_state.state1.outputs.suffix
}

resource "aws_iam_role" "lambda" {
  name = "dynamodb-table-write-${local.suffix}"
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

data "aws_dynamodb_table" "example" {
  name = "dynamodb-table-write-${local.suffix}"
}

resource "aws_iam_role_policy" "lambda" {
  name = "dynamodb-table-write-${local.suffix}"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Action" : [
          "dynamodb:PutItem"
        ],
        "Effect" : "Allow",
        "Resource" : data.aws_dynamodb_table.example.arn
      }
    ]
  })
}

resource "null_resource" "example" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -rf ./external
    EOT
  }
}

resource "aws_lambda_function" "example" {
  filename         = "${path.module}/external/write_dynamodb_table_item.zip"
  function_name    = "dynamodb-table-write-${local.suffix}"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/external/write_dynamodb_table_item.zip")
  runtime          = "python3.12"
  environment {
    variables = {
      TABLE_NAME = data.aws_dynamodb_table.example.name
      TABLE_ITEM = "{\"source\": \"example_source\", \"timestamp\": \"2024-07-22T19:29:09\", \"region\": \"ap-southeast-1\"}"
    }
  }
}
