locals {
  tags = module.utils.cost_tags

  ignoreNamingConvention = var.ignore_naming_convention ? var.name : ""
  isFifo = var.fifo_topic ? format(
    "%s-%s-%s-%s.fifo",
    var.service,
    module.utils.environment_short_name,
    var.name,
    module.utils.region_short_name
    ) : format("%s-%s-%s-%s",
    var.service,
    module.utils.environment_short_name,
    var.name,
  module.utils.region_short_name)
  name = coalesce(local.ignoreNamingConvention, local.isFifo)
}



module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.0.1"
  create  = var.create
  

  # Topic Configuration
  name                        = local.name
  use_name_prefix             = false
  application_feedback        = var.application_feedback
  content_based_deduplication = var.content_based_deduplication
  delivery_policy             = var.delivery_policy
  display_name                = local.name
  fifo_topic                  = var.fifo_topic
  firehose_feedback           = var.firehose_feedback
  http_feedback               = var.http_feedback
  kms_master_key_id           = var.kms_master_key_id
  lambda_feedback             = var.lambda_feedback
  topic_policy                = var.topic_policy
  sqs_feedback                = var.sqs_feedback
  signature_version           = var.signature_version
  tracing_config              = var.tracing_config
  archive_policy              = var.archive_policy

  # Topic Policy Configuration
  create_topic_policy             = var.create_topic_policy
  source_topic_policy_documents   = var.source_topic_policy_documents
  override_topic_policy_documents = var.override_topic_policy_documents
  enable_default_topic_policy     = var.enable_default_topic_policy
  topic_policy_statements         = var.topic_policy_statements

  # Subscription Configuration
  create_subscription = var.create_subscription
  subscriptions       = var.subscriptions

  # Data Protection Configuration
  data_protection_policy = var.data_protection_policy

  # Tags
  tags = local.tags

}
