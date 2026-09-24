variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region for deployment"
}

variable "instance_type" {
  type        = string
  default     = "t3.large"
  description = "EC2 Instance type"
}

variable "ami_id" {
  type        = string
  default     = "ami-0c7217cdde317cfec"
  description = "Ubuntu 24.04 AMI ID"
}
