#!/bin/bash

set -e

cd "$(dirname "$0")"
source .env

TF_COMMAND=$1

if [ -z $TF_COMMAND ]; then
  echo "Usage: ./provision.sh [plan|apply|destroy]"
  exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account' --profile $AWS_PROFILE)
EXPRESS_ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

# ensure terraform state bucket exists
existing_tf_bucket=$(aws --profile $AWS_PROFILE s3api list-buckets --query "Buckets[?Name=='${TF_STATE_BUCKET}'].Name" --output text)
if [ -z $existing_tf_bucket ]; then
  aws --profile $AWS_PROFILE s3api create-bucket --bucket $TF_STATE_BUCKET
fi

# init terraform & s3 backend
rm -f *.tfstate
rm -rf ./.terraform
terraform init \
  -force-copy \
  -backend=true \
  -backend-config "bucket=${TF_STATE_BUCKET}" \
  -backend-config "key=${TF_STATE_KEY}" \
  -backend-config "profile=${AWS_PROFILE}" \
  -backend-config "region=${AWS_REGION}"

# execute terraform
terraform $TF_COMMAND \
  -var "aws_key_name=${AWS_KEY_NAME}" \
  -var "aws_profile=${AWS_PROFILE}" \
  -var "aws_region=${AWS_REGION}" \
  -var "aws_security_group_ids=${AWS_SECURITY_GROUP_IDS}" \
  -var "aws_subnet_id=${AWS_SUBNET_ID}" \
  -var "ec2_ami_id=${EC2_AMI_ID}" \
  -var "ec2_instance_type=${EC2_INSTANCE_TYPE}" \
  -var "express_ecr_image=${EXPRESS_ECR_IMAGE}" \
  -var "s3_data_bucket=${S3_DATA_BUCKET}"
