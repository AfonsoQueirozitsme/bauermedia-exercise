variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (ARM Graviton)"
  default     = "t4g.small"
}
