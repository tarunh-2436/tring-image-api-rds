output "topic_id" {
  description = "SNS Topic ID"
  value       = aws_sns_topic.this.id
}

output "topic_name" {
  description = "SNS Topic Name"
  value       = aws_sns_topic.this.name
}

output "topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.this.arn
}