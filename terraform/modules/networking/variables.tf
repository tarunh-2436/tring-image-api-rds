variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones for the subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two Availability Zones must be provided."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs must be provided."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) == length(var.public_subnet_cidrs) &&
      length(var.availability_zones) == length(var.private_subnet_cidrs)
    )

    error_message = "The number of availability zones, public subnet CIDRs, and private subnet CIDRs must match."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}