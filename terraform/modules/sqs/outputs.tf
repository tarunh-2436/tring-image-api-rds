output "queue_id" {
  description = "SQS Queue ID"
  value       = aws_sqs_queue.this.id
}

output "queue_name" {
  description = "SQS Queue Name"
  value       = aws_sqs_queue.this.name
}

output "queue_url" {
  description = "SQS Queue URL"
  value       = aws_sqs_queue.this.url
}

output "queue_arn" {
  description = "SQS Queue ARN"
  value       = aws_sqs_queue.this.arn
}

output "dead_letter_queue_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.dlq.url
}

output "dead_letter_queue_arn" {
  description = "Dead Letter Queue ARN"
  value       = aws_sqs_queue.dlq.arn
}