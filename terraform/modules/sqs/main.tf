###############################################
# Dead Letter Queue
###############################################

resource "aws_sqs_queue" "dlq" {

  name = "${var.queue_name}-dlq"

  message_retention_seconds = 1209600

  tags = merge(
    var.tags,
    {
      Name = "${var.queue_name}-dlq"
    }
  )
}

###############################################
# Primary Queue
###############################################

resource "aws_sqs_queue" "this" {

  name = var.queue_name

  visibility_timeout_seconds = 60

  message_retention_seconds = 345600

  receive_wait_time_seconds = 20

  redrive_policy = jsonencode({

    deadLetterTargetArn = aws_sqs_queue.dlq.arn

    maxReceiveCount = 5
  })

  tags = merge(
    var.tags,
    {
      Name = var.queue_name
    }
  )
}