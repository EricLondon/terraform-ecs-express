# AWS S3 bucket
# TF: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
# AWS: http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
resource "aws_s3_bucket" "s3_data_bucket" {
  bucket = "${var.s3_data_bucket}"
  acl    = "private"

  tags {
    Name = "Eric Data Bucket"
  }
}

# [Data] IAM policy to define S3 permissions
# TF: https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
data "aws_iam_policy_document" "s3_data_bucket_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_data_bucket.bucket}"
    ]
  }
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_data_bucket.bucket}/*"
    ]
  }
}

# AWS IAM policy
# TF: https://www.terraform.io/docs/providers/aws/r/iam_policy.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
resource "aws_iam_policy" "s3_policy" {
  name   = "eric-s3-policy"
  policy = "${data.aws_iam_policy_document.s3_data_bucket_policy.json}"
}

# Attaches a managed IAM policy to an IAM role
# TF: https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/attach-role-policy.html
resource "aws_iam_role_policy_attachment" "ecs_role_s3_data_bucket_policy_attach" {
  role       = "${aws_iam_role.ecs_role.name}"
  policy_arn = "${aws_iam_policy.s3_policy.arn}"
}
