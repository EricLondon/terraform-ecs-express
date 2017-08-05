terraform {
  backend "s3" {
    bucket  = ""
    key     = ""
    profile = ""
    region  = ""
  }
}

/*
data "aws_caller_identity" "current" {
}
*/

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

resource "aws_ecs_cluster" "eric_express" {
  name = "eric-express"
}

resource "aws_iam_role" "ecs_role" {
  name               = "eric-ecs-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role_policy.json}"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "eric-instance-profile"
  role = "${aws_iam_role.ecs_role.name}"
}

data "aws_ecs_task_definition" "express_ecs_task_definition" {
  task_definition = "${aws_ecs_task_definition.express_ecs_task_definition.family}"
}

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

resource "aws_ecs_service" "express_ecs_service" {
  name            = "eric-express-ecs-service"
  cluster         = "${aws_ecs_cluster.eric_express.id}"
  desired_count   = 1
  task_definition = "${aws_ecs_task_definition.express_ecs_task_definition.family}:${max("${aws_ecs_task_definition.express_ecs_task_definition.revision}", "${data.aws_ecs_task_definition.express_ecs_task_definition.revision}")}"
}

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
