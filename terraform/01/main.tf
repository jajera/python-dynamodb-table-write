resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_iam_user" "example" {
  name = "py-user-${random_string.suffix.result}"
}

resource "aws_iam_access_key" "example" {
  user = aws_iam_user.example.name
}

resource "aws_dynamodb_table" "example" {
  name         = "dynamodb-table-write-${random_string.suffix.result}"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "source"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  hash_key  = "source"
  range_key = "timestamp"

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_policy" "dynamodb_table" {
  name = "dynamodb-table-write-${random_string.suffix.result}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.example.arn
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "dynamodb_table" {
  user       = aws_iam_user.example.name
  policy_arn = aws_iam_policy.dynamodb_table.arn
}

resource "null_resource" "example" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "#!/bin/bash" > terraform.tmp
      echo "export AWS_ACCESS_KEY_ID=${aws_iam_access_key.example.id}" >> terraform.tmp
      echo "export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.example.secret}" >> terraform.tmp
      echo "export AWS_REGION=${data.aws_region.current.name}" >> terraform.tmp
      chmod +x terraform.tmp
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f terraform.tmp
    EOT
  }
}

output "aws_dynamodb_table_name" {
  value = aws_dynamodb_table.example.name
}

output "suffix" {
  value = random_string.suffix.result
}
