variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name of the project"
  default     = "devops-lab-2026"
}
variable "key_name" {
  description = "The name of the SSH key pair created in the AWS Console"
  type        = string
  default     = "devops-project-key"
}