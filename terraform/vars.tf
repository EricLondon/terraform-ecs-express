provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  max_retries = "10"
}

variable "aws_key_name" {
  type = "string"
}

variable "aws_profile" {
  type = "string"
}

variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "aws_security_group_ids" {
  type = "list"
}

variable "aws_subnet_id" {
  type = "string"
}

variable "ec2_ami_id" {
  type = "string"
}

variable "ec2_instance_type" {
  type = "string"
}

variable "express_ecr_image" {
  type = "string"
}

variable "s3_data_bucket" {
  type = "string"
}
