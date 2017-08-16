terraform {
  # Stores the Terraform state in S3
  # https://www.terraform.io/docs/backends/types/s3.html
  backend "s3" {
    bucket  = ""
    key     = ""
    profile = ""
    region  = ""
  }
}
