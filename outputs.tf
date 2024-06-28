################################################################################
# Topic
################################################################################

output "topic_arn" {
  description = "The ARN of the SNS topic, as a more obvious property (clone of id)"
  value       = module.sns_topic.topic_arn
}

output "topic_id" {
  description = "The ID of the SNS topic"
  value       = module.sns_topic.topic_id
}

output "topic_name" {
  description = "The name of the topic"
  value       = module.sns_topic.topic_name
}

output "topic_owner" {
  description = "The AWS Account ID of the SNS topic owner"
  value       = module.sns_topic.topic_owner
}

output "topic_beginning_archive_time" {
  description = "The oldest timestamp at which a FIFO topic subscriber can start a replay"
  value       = module.sns_topic.topic_beginning_archive_time
}

################################################################################
# Subscription(s)
################################################################################

output "subscriptions" {
  description = "Map of subscriptions created and their attributes"
  value       = module.sns_topic.subscriptions
}