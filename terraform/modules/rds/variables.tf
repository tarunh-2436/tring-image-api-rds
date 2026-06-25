variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}

variable "database_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs must be provided."
  }
}

variable "security_group_ids" {
  description = "Security Groups attached to the database"
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}