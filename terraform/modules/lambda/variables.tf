variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_path" {
  description = "Path to the Lambda source code"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Group IDs for VPC configuration"
  type        = list(string)
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "runtime" {
  description = "Python runtime"
  type        = string
  default     = "python3.13"
}

variable "memory_size" {
  description = "Memory allocated to the Lambda function"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}