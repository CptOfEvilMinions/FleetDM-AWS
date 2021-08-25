# ############################## Create a cluster ##############################
# resource "aws_ecs_cluster" "fleet_ecs_cluster" {
#   name = "${var.FLEET_PREFIX}_ecs_cluster"
#   tags = {
#     Team = var.team
#   }
# }

# ############################## Create an ECS service ##############################
# resource "aws_ecs_service" "fleet_ecs_service" {
#   name            = "${var.FLEET_PREFIX}_ecs_service"
#   task_definition = aws_ecs_task_definition.fleet_ecs_web.arn
#   cluster         = aws_ecs_cluster.fleet_ecs_cluster.id
#   launch_type     = "FARGATE"


#   tags = {
#     Team = var.team
#   }
# }

# ############################## Create IAM role ##############################
# # The assume_role_policy field works with the following aws_iam_policy_document to allow
# # ECS tasks to assume this role we're creating.
# resource "aws_iam_role" "sun-api-task-execution-role" {
#   name               = "sun-api-task-execution-role"
#   assume_role_policy = data.aws_iam_policy_document.ecs-task-assume-role.json
#   tags = {
#     Team = var.team
#   }
# }

# data "aws_iam_policy_document" "ecs-task-assume-role" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy" "ecs-task-execution-role" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_iam_role_policy_attachment" "ecs-task-execution-role" {
#   role       = aws_iam_role.sun-api-task-execution-role.name
#   policy_arn = data.aws_iam_policy.ecs-task-execution-role.arn
#   tags = {
#     Team = var.team
#   }
# }


# ############################## Create Cloudwatch for ECS ##############################
# resource "aws_cloudwatch_log_group" "fleet_ecs_cloudwatch" {
#   name = "/ecs/fleet_ecs_cloudwatch"
#   tags = {
#     Team = var.team
#   }
# }

# ############################## Create ECS task ##############################
# resource "aws_ecs_task_definition" "fleet_ecs_web" {
#   family = "fleet_ecs_service"
#   execution_role_arn = aws_iam_role.sun-api-task-execution-role.arn

#   container_definitions = <<EOF
#   [
#     {
#       "name": "fleet_ecs_web",
#       "image": "fleetdm/fleet:v${var.fleet_version}",
#       "portMappings": [
#         {
#           "containerPort": 8080
#         }
#       ],
#       "logConfiguration": {
#         "logDriver": "awslogs",
#         "options": {
#           "awslogs-region": "${var.region}",
#           "awslogs-group": "/ecs/fleet_ecs_cloudwatch",
#           "awslogs-stream-prefix": "ecs"
#         }
#       }
#     }
#   ]
#   EOF

#   # These are the minimum values for Fargate containers.
#   cpu = 256
#   memory = 512
#   requires_compatibilities = ["FARGATE"]

#   # This is required for Fargate containers (more on this later).
#   network_mode = "awsvpc"
#   tags = {
#     Team = var.team
#   }
# }
