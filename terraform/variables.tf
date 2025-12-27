variable "bucket_name" {
  description = "Name of the S3 bucket for website hosting (must be globally unique)"
  type        = string
  default     = "my-website-template-bucket"  # CUSTOMIZE: Change to your unique bucket name
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"  # Change to your preferred region
}

