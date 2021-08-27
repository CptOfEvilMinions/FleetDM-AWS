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

  desired_count = 3

  network_configuration {
    assign_public_ip = false

    security_groups = [aws_security_group.fleet_ingress_sg.id]
    subnets = [
      aws_subnet.fleet_private_a_subnet.id,
      aws_subnet.fleet_private_b_subnet.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = "fleet_ecs_web"
    container_port   = 8080
  }

  depends_on = [aws_alb_listener.main]

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
data "aws_iam_policy_document" "fleet" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.database_password_secret.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS*"]
    condition {
      test = "StringLike"
      values = [
        "ecs.amazonaws.com"
      ]
      variable = "iam:AWSServiceName"
    }
  }

}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "main" {
  name               = "fleetdm-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.main.name
}

resource "aws_iam_policy" "main" {
  name   = "fleet-iam-policy"
  policy = data.aws_iam_policy_document.fleet.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  policy_arn = aws_iam_policy.main.arn
  role       = aws_iam_role.main.name
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
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_ecs_task_definition" "fleet_ecs_web" {
  family = "fleet_ecs_service"
  

  container_definitions = jsonencode(
  [
    {
      "name": "fleet_ecs_web",
      "image": "fleetdm/fleet:v${var.fleet_version}",
      "cpu": 256,
      "memory": 512,
      mountPoints = []
      volumesFrom = []
      essential   = true
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      networkMode = "awsvpc"
      command = ["sh", "-c", "fleet prepare db && fleet serve"]
      "secrets": [
        {
          "name": "FLEET_MYSQL_PASSWORD",
          "valueFrom": aws_secretsmanager_secret.database_password_secret.arn
        }
      ],
      environment = [
        {
          name  = "FLEET_MYSQL_USERNAME"
          value = "fleet"
        },
        {
          name  = "FLEET_MYSQL_ADDRESS"
          value = "${aws_db_instance.fleet_mysql_server.endpoint}"
        },
        {
          name  = "FLEET_REDIS_ADDRESS"
          value = "${aws_elasticache_cluster.fleet_redis.cache_nodes.0.address}:6379"
        },
        {
          name  = "FLEET_SERVER_TLS"
          value = "false"
        }
      ]
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-region": "${var.region}",
          "awslogs-group": "/ecs/fleet_ecs_cloudwatch",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.main.arn
  task_role_arn            = aws_iam_role.main.arn

  tags = {
    Team = var.team
  }

}