provider "aws" {
  region = "us-east-1"
}

module "identity_center" {
  source = "../../" # the path to module

  accounts_aws = {
    root = {
      id = "88888888888"
    }
    development = {
      id = "77777777777"
    }
    staging = {
      id = "66666666666"
    }
    production = {
      id = "55555555555"
    }
    shared = {
      id = "44444444444"
    }
  }

  teams = {
    DevTeam = {
      description  = "Developers"
      allowed_accounts = ["development", "staging"]
      session_duration = "PT12H"
      permission_set = {
        description = "Developer full access to AWS"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/PowerUserAccess"
        ]
        customer_managed_policies = [
           "arn:aws:iam::aws:policy/lambda-dev-access"
        ]
      }
    }

    DevOpsTeam = {
      description  = "DevOps Engineers"
      allowed_accounts = ["development", "staging", "production", "shared"]
      session_duration = "PT12H"
      permission_set = {
        description = "DevOps team access"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/PowerUserAccess"
        ]
        customer_managed_policies = []
      }
    }

    SecurityTeam = {
      description  = "Security"
      allowed_accounts = ["development", "staging", "production", "shared", "root"]
      session_duration = "PT12H"
      permission_set = {
        description = "Sec team access"
        aws_managed_policies = [
         "arn:aws:iam::aws:policy/PowerUserAccess"
        ]
        customer_managed_policies = [
        ]
      }
    }
  }
}


# Custom IAM Policy for Lambda Dev Access example to be used in Permission Sets for example purposes
resource "aws_iam_policy" "lambda_dev_access" {
  name        = "lambda-dev-access"
  description = "Allow full access to AWS Lambda and related CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LambdaFullAccess",
        Effect = "Allow",
        Action = [
          "lambda:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsAccess",
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },
      {
        Sid    = "IAMPassRoleForLambda",
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = "*",
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}


