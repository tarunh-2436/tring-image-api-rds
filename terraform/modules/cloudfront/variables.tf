variable "distribution_name" {
  description = "Name of the CloudFront distribution"
  type        = string
}

variable "origin_domain_name" {
  description = "Origin domain name"
  type        = string
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}