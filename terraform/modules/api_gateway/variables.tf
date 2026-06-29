variable "api_name" {
  description = "Name of the HTTP API"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront domain name for CORS configuration"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}