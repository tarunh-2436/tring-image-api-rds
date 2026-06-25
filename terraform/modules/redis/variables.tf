variable "identifier" {
  description = "Unique identifier for the Redis replication group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the Redis subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided."
  }
}

variable "security_group_ids" {
  description = "Security Groups attached to Redis"
  type        = list(string)
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}