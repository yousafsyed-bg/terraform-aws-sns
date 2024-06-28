

data "aws_caller_identity" "current" {}

locals {
  region = "us-east-1"
}

################################################################################
# SNS Module
################################################################################

module "default_sns" {
  source = "../../"

  environment       = "qa"
  service           = "test"
  product           = "sync"
  costtype          = "opex"
  owner             = "platform"
  region            = local.region
  name              = "default"
  signature_version = 2

  data_protection_policy = jsonencode(
    {
      Description = "Deny Inbound Address"
      Name        = "DenyInboundEmailAdressPolicy"
      Statement = [
        {
          "DataDirection" = "Inbound"
          "DataIdentifier" = [
            "arn:aws:dataprotection::aws:data-identifier/EmailAddress",
          ]
          "Operation" = {
            "Deny" = {}
          }
          "Principal" = [
            "*",
          ]
          "Sid" = "DenyInboundEmailAddress"
        },
      ]
      Version = "2021-06-01"
    }
  )


}

module "complete_sns" {
  source = "../../"

  name              = "complete"
  environment       = "qa"
  service           = "test"
  product           = "sync"
  costtype          = "opex"
  owner             = "platform"
  region            = local.region
  kms_master_key_id = module.kms.key_id
  tracing_config    = "Active"

  # SQS queue must be FIFO as well
  fifo_topic                  = true
  content_based_deduplication = true

  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })

  # # Example config for archive_policy for SNS FIFO message archiving
  # # You can not delete a topic with an active message archive policy
  # # You must first deactivate the topic before it can be deleted
  # # https://docs.aws.amazon.com/sns/latest/dg/message-archiving-and-replay-topic-owner.html
  # archive_policy = jsonencode({
  #   "MessageRetentionPeriod": 30
  # })

  create_topic_policy         = true
  enable_default_topic_policy = true
  topic_policy_statements = {
    pub = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "AWS"
        identifiers = [data.aws_caller_identity.current.arn]
      }]
    },

    sub = {
      actions = [
        "sns:Subscribe",
        "sns:Receive",
      ]

      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]

      conditions = [{
        test     = "StringLike"
        variable = "sns:Endpoint"
        values   = [module.sqs.queue_arn]
      }]
    }
  }

  subscriptions = {
    sqs = {
      protocol = "sqs"
      endpoint = module.sqs.queue_arn

      # # example of replay_policy for SNS FIFO message replay
      # # https://docs.aws.amazon.com/sns/latest/dg/message-archiving-and-replay-subscriber.html
      # replay_policy = jsonencode({
      #   "PointType": "Timestamp"
      #   "StartingPoint": timestamp()
      # })
    }
  }

  # Feedback
  application_feedback = {
    failure_role_arn    = aws_iam_role.this.arn
    success_role_arn    = aws_iam_role.this.arn
    success_sample_rate = 100
  }
  firehose_feedback = {
    failure_role_arn    = aws_iam_role.this.arn
    success_role_arn    = aws_iam_role.this.arn
    success_sample_rate = 100
  }
  http_feedback = {
    failure_role_arn    = aws_iam_role.this.arn
    success_role_arn    = aws_iam_role.this.arn
    success_sample_rate = 100
  }
  lambda_feedback = {
    failure_role_arn    = aws_iam_role.this.arn
    success_role_arn    = aws_iam_role.this.arn
    success_sample_rate = 100
  }
  sqs_feedback = {
    failure_role_arn    = aws_iam_role.this.arn
    success_role_arn    = aws_iam_role.this.arn
    success_sample_rate = 100
  }


}

module "disabled_sns" {
  source = "../../"

  create = false
  name   = "disabled"

  environment = "qa"
  service     = "test"
  product     = "sync"
  costtype    = "opex"
  owner       = "platform"
  region      = local.region
}

################################################################################
# Supporting Resources
################################################################################

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.0"

  aliases     = ["sns/alias-test-kms-key"]
  description = "KMS key to encrypt topic"

  # Policy
  key_statements = [
    {
      sid = "SNS"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }]
    }
  ]
}

module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name       = "test-sqs"
  fifo_queue = true

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "SNS"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.complete_sns.topic_arn]
        }
      ]
    }
  }


}

resource "aws_iam_role" "this" {
  name = "test-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "SnsAssume"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "test-sns-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:PutMetricFilter",
            "logs:PutRetentionPolicy",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}
