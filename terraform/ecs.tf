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

# AWS ECS cluster
# TF: https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html
# AWS: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_clusters.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/ecs/create-cluster.html
resource "aws_ecs_cluster" "eric_express" {
  name = "eric-express"
}

# [Data] IAM policy document (to allow ECS tasks to assume a role)
# TF: https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-policy.html
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# AWS IAM role (to allow ECS tasks to assume a role)
# TF: https://www.terraform.io/docs/providers/aws/r/iam_role.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/create-role.html
resource "aws_iam_role" "ecs_role" {
  name               = "eric-ecs-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role_policy.json}"
}

# AWS IAM instance profile
# TF: https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html
# AWS: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/IAM_policies.html
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "eric-instance-profile"
  role = "${aws_iam_role.ecs_role.name}"
}

# [Data] AWS ECS task definition
# Simply specify the family to find the latest ACTIVE revision in that family.
# TF: https://www.terraform.io/docs/providers/aws/d/ecs_task_definition.html
# AWS: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html
data "aws_ecs_task_definition" "express_ecs_task_definition" {
  task_definition = "${aws_ecs_task_definition.express_ecs_task_definition.family}"
}

# AWS ECS task definition
# TF: https://www.terraform.io/docs/providers/aws/d/ecs_task_definition.html
# AWS: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/ecs/register-task-definition.html
resource "aws_ecs_task_definition" "express_ecs_task_definition" {
  family                = "eric-express"
  task_role_arn         = "${aws_iam_role.ecs_role.arn}"
  container_definitions = <<DEFINITION
[
  {
    "name": "express",
    "command": ["node", "app.js"],
    "essential": true,
    "image": "${var.express_ecr_image}",
    "memoryReservation": 128,
    "privileged": false,
    "portMappings": [
      {
        "hostPort": 80,
        "containerPort": 80,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "S3_DATA_BUCKET",
        "value": "${aws_s3_bucket.s3_data_bucket.bucket}"
      }
    ]
  }
]
DEFINITION
}

# AWS ECS service
# TF: https://www.terraform.io/docs/providers/aws/r/ecs_service.html
# AWS: http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/ecs/create-service.html
resource "aws_ecs_service" "express_ecs_service" {
  name            = "eric-express-ecs-service"
  cluster         = "${aws_ecs_cluster.eric_express.id}"
  desired_count   = 1
  task_definition = "${aws_ecs_task_definition.express_ecs_task_definition.family}:${max("${aws_ecs_task_definition.express_ecs_task_definition.revision}", "${data.aws_ecs_task_definition.express_ecs_task_definition.revision}")}"
}

# AWS EC2 instance
# TF: https://www.terraform.io/docs/providers/aws/r/instance.html
# AWS: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Instances.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
resource "aws_instance" "express_ec2" {
  ami                    = "${var.ec2_ami_id}"
  instance_type          = "${var.ec2_instance_type}"
  key_name               = "${var.aws_key_name}"
  subnet_id              = "${var.aws_subnet_id}"
  vpc_security_group_ids = "${var.aws_security_group_ids}"
  iam_instance_profile   = "ecsInstanceRole"
  tags {
    name = "Eric Express ECS"
  }
  user_data = <<SCRIPT
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.eric_express.name} >> /etc/ecs/ecs.config
SCRIPT
}

output "ApplicationEndpoint" {
  value = "http://${aws_instance.express_ec2.private_ip}"
}
