#!/bin/bash

set -e
set -x

cd "$(dirname "$0")"

AWS_PROFILE="${AWS_PROFILE:-default}"
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO="${ECR_REPO:-eric-test/express}"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account' --profile $AWS_PROFILE)

# ensure ECR repository exists
existing_repo=$(aws --profile $AWS_PROFILE ecr describe-repositories --query "repositories[?repositoryName=='${ECR_REPO}'].repositoryName" --output text)
if [ -z $existing_repo ]; then
  aws --profile $AWS_PROFILE ecr create-repository --repository-name $ECR_REPO
fi

docker_login=$(aws ecr get-login --no-include-email --region $AWS_REGION)
eval $docker_login
docker build -t $ECR_REPO .
docker tag $ECR_REPO:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
