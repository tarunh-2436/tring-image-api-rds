output "distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "Distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront Hosted Zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "oac_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.this.id
}