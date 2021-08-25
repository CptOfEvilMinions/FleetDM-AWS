# ############################################# Create Cloudwatch ############################################
# resource "aws_cloudwatch_log_group" "fleet_cloudwatch" {
#   name              = "Fleet"
#   retention_in_days = 60

#   tags = {
#     Name = "${var.FLEET_PREFIX}_VPC"
#     Team = var.team
#     Application = "Fleet"
#     Environment = "production"
#   }
# }

# ############################################# Cloudwatch redis #############################################
# data "aws_iam_policy_document" "redis-log-publishing-policy" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:PutLogEventsBatch",
#     ]

#     resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticache/*"]

#     principals {
#       identifiers = ["elasticache.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "redis-log-publishing-policy" {
#   policy_document = data.aws_iam_policy_document.redis-log-publishing-policy.json
#   policy_name     = "redis-log-publishing-policy"
# }

# ############################################# Cloudwatch mysql #############################################
# data "aws_iam_policy_document" "rds-log-publishing-policy" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:PutLogEventsBatch",
#     ]

#     resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/*"]


#     principals {
#       identifiers = ["rds.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "rds-log-publishing-policy" {
#   policy_document = data.aws_iam_policy_document.rds-log-publishing-policy.json
#   policy_name     = "rds-log-publishing-policy"
# }


# ############################################# Cloudwatch ECS #############################################
# data "aws_iam_policy_document" "ecs-log-publishing-policy" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:PutLogEventsBatch",
#     ]

#     resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/*"]


#     principals {
#       identifiers = ["ecs.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "ecs-log-publishing-policy" {
#   policy_document = data.aws_iam_policy_document.ecs-log-publishing-policy.json
#   policy_name     = "ecs-log-publishing-policy"
# }

# ############################################# Cloudwatch ELB #############################################
# data "aws_iam_policy_document" "elb-log-publishing-policy" {
#   statement {
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:PutLogEventsBatch",
#     ]

#     resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elb/*"]


#     principals {
#       identifiers = ["elb.amazonaws.com"]
#       type        = "Service"
#     }
#   }
# }

# resource "aws_cloudwatch_log_resource_policy" "elb-log-publishing-policy" {
#   policy_document = data.aws_iam_policy_document.elb-log-publishing-policy.json
#   policy_name     = "elb-log-publishing-policy"
# }