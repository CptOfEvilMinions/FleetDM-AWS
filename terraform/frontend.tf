############################## Create load balancer for ECS ##############################
resource "aws_security_group" "lb" {
  name        = "${var.FLEET_PREFIX} load balancer"
  description = "${var.FLEET_PREFIX} Load balancer security group"
  vpc_id      = aws_vpc.fleet_vpc.id
}

resource "aws_security_group_rule" "lb-ingress" {
  description = "${var.FLEET_PREFIX}: allow traffic from public internet"
  type        = "ingress"

  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb-http-ingress" {
  description = "${var.FLEET_PREFIX}: allow traffic from public internet"
  type        = "ingress"

  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}

# Allow outbound traffic
resource "aws_security_group_rule" "lb-egress" {
  description = "${var.FLEET_PREFIX}: allow all outbound traffic"
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group" "backend" {
  name        = "${var.FLEET_PREFIX} backend"
  description = "${var.FLEET_PREFIX} Backend security group"
  vpc_id      = aws_vpc.fleet_vpc.id

}

# Allow traffic from the load balancer to the backends
resource "aws_security_group_rule" "backend-ingress" {
  description = "${var.FLEET_PREFIX}: allow traffic from load balancer"
  type        = "ingress"

  from_port                = "8080"
  to_port                  = "8080"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id = aws_security_group.backend.id
}

# Allow outbound traffic from the backends
resource "aws_security_group_rule" "backend-egress" {
  description = "${var.FLEET_PREFIX}: allow all outbound traffic"
  type        = "egress"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.backend.id
}

resource "aws_alb" "main" {
  name                = "fleetdm"
  load_balancer_type  = "application"
  internal            = false
  security_groups     = [
    aws_security_group.lb.id, 
    aws_security_group.backend.id
  ]
  subnets             = [
    aws_subnet.fleet_public_A_subnet.id,
    aws_subnet.fleet_public_B_subnet.id
  ]
}

resource "aws_alb_target_group" "main" {
  name                 = "fleetdm"
  protocol             = "HTTP"
  target_type          = "ip"
  port                 = "8080"
  vpc_id               = aws_vpc.fleet_vpc.id
  deregistration_delay = 30

  health_check {
    path                = "/healthz"
    matcher             = "200"
    timeout             = 10
    interval            = 15
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  depends_on = [aws_alb.main]
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type = "forward"
  }
}