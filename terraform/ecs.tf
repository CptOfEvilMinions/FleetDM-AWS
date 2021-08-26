############################## Create a cluster ##############################
resource "aws_ecs_cluster" "fleet_ecs_cluster" {
  name = "${var.FLEET_PREFIX}_ecs_cluster"
  tags = {
    Team = var.team
  }
}

############################## Create an ECS service ##############################
resource "aws_ecs_service" "fleet_ecs_service" {
  name            = "${var.FLEET_PREFIX}_ecs_service"
  task_definition = aws_ecs_task_definition.fleet_ecs_web.arn
  cluster         = aws_ecs_cluster.fleet_ecs_cluster.id
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    assign_public_ip = false

    security_groups = [aws_security_group.fleet_ingress_sg.id]
    subnets = [
      aws_subnet.fleet_private_a_subnet.id,
      aws_subnet.fleet_private_b_subnet.id,
    ]
  }

  tags = {
    Team = var.team
  }
}

############################## Auto scaling ##############################
# resource "aws_appautoscaling_target" "app_scale_target" {
#   service_namespace  = "ecs"
#   resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
#   scalable_dimension = "ecs:service:DesiredCount"
#   max_capacity       = var.ecs_autoscale_max_instances
#   min_capacity       = var.ecs_autoscale_min_instances
# }


############################## Create IAM role ##############################
# The assume_role_policy field works with the following aws_iam_policy_document to allow
# ECS tasks to assume this role we're creating.
resource "aws_iam_role" "fleet-task-execution-role" {
  name               = "fleet-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-task-assume-role.json
}

data "aws_iam_policy_document" "ecs-task-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Normally we'd prefer not to hardcode an ARN in our Terraform, but since this is
# an AWS-managed policy, it's okay.
data "aws_iam_policy" "ecs-task-execution-role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role" {
  role       = aws_iam_role.fleet-task-execution-role.name
  policy_arn = data.aws_iam_policy.ecs-task-execution-role.arn
}

############################## Create Cloudwatch for ECS ##############################
resource "aws_cloudwatch_log_group" "fleet_ecs_cloudwatch" {
  name = "/ecs/fleet_ecs_cloudwatch"
  retention_in_days = 90
  tags = {
    Team = var.team
  }
}

############################## Create ECS task ##############################
resource "aws_security_group" "fleet_ingress_sg" {
  name        = "${var.FLEET_PREFIX}_ingress_sg"
  description = "Allow ingress to Fleet"
  vpc_id      = aws_vpc.fleet_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ecs_task_definition" "fleet_ecs_web" {
  family = "fleet_ecs_service"
  

  container_definitions = <<EOF
  [
    {
      "name": "fleet_ecs_web",
      "image": "fleetdm/fleet:v${var.fleet_version}",
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "memory": 512,
      "cpu": 256,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${var.region}",
          "awslogs-group": "/ecs/fleet_ecs_cloudwatch",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  EOF

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.fleet-task-execution-role.arn
  
  tags = {
    Team = var.team
  }

}