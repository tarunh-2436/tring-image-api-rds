###############################################
# HTTP API
###############################################

resource "aws_apigatewayv2_api" "this" {

  name = var.api_name

  protocol_type = "HTTP"

  tags = merge(
    var.tags,
    {
      Name = var.api_name
    }
  )
}

###############################################
# Default Stage
###############################################

resource "aws_apigatewayv2_stage" "this" {

  api_id = aws_apigatewayv2_api.this.id

  name = "$default"

  auto_deploy = true

  tags = merge(
    var.tags,
    {
      Name = "${var.api_name}-stage"
    }
  )
}