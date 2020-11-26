## This tf file will setup Datadog AWS integration

resource "datadog_integration_aws" "core" {
  count      = var.enable_datadog_aws_integration ? 1 : 0
  account_id = var.aws_account_id
  role_name  = "datadog-integration-role"

  host_tags = [
    "Namespace:${var.namespace}",
    "env:${var.env}"
  ]

  account_specific_namespace_rules = var.account_specific_namespace_rules
  excluded_regions                 = var.excluded_regions
  filter_tags                      = var.filter_tags
}

resource "aws_iam_role" "datadog-integration" {
  count = var.enable_datadog_aws_integration ? 1 : 0
  name  = "datadog-integration-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::464622532012:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${datadog_integration_aws.core[0].external_id}"
        }
      }
    }
  ]
}
EOF

  tags = merge(local.default_tags, {
    description = "This role allows the datadog AWS account to access this account for metrics collection"
  })
}

resource "aws_iam_policy" "datadog-core" {
  count       = var.enable_datadog_aws_integration ? 1 : 0
  name        = "datadog-core-integration"
  path        = "/"
  description = "This IAM policy allows for core datadog integration permissions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        
        "ecs:Describe*",
        "ecs:List*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "ec2:Describe*",
        "support:*",
        "tag:GetResources",
        "tag:GetTagKeys",
        "tag:GetTagValues"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "datadog-core-attach" {
  count      = var.enable_datadog_aws_integration ? 1 : 0
  role       = aws_iam_role.datadog-integration[0].name
  policy_arn = aws_iam_policy.datadog-core[0].arn
}
