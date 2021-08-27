################################################### Public domain ###################################################
# resource "aws_acm_certificate" "fleet_public_cert" {
#   domain_name       = "fleet.${var.public_domain}"
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.FLEET_PREFIX}_public_cert"
#     Team = var.team
#   }
# }

# data "aws_route53_zone" "public_domain" {
#   name = var.public_domain
  
#   tags = {
#     Name = "${var.FLEET_PREFIX}_route53_public_zone"
#     Team = var.team
#   }
# }

# resource "aws_route53_record" "public_domain_records" {
#   for_each = {
#     for dvo in aws_acm_certificate.fleet_public_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.public_domain.zone_id
# }

# resource "aws_acm_certificate_validation" "fleet_public_cert_validation" {
#   certificate_arn         = aws_acm_certificate.fleet_public_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.public_domain_records : record.fqdn]
# }

# resource "aws_route53_record" "fleet_server" {
#   zone_id = aws_route53_zone.public_domain.zone_id
#   name    = "fleet.${var.public_domain}"
#   type    = "A"

#   allow_overwrite = true
#   alias {
#     name                   = aws_alb.main.dns_name
#     zone_id                = aws_alb.main.zone_id
#     evaluate_target_health = true
#   }
# }


# This data source looks up the public DNS zone

resource "aws_route53_zone" "public_domain" {
  name         = var.public_domain

  tags = {
    Team = var.team
  }
}
data "aws_route53_zone" "public_domain" {
  name         = var.public_domain
  private_zone = false

  depends_on = [
    aws_route53_zone.public_domain,
  ]
}

# resource "aws_route53_record" "public_domain_nameservers" {
#   zone_id = aws_route53_zone.public_domain.zone_id
#   name    = var.public_domain
#   type    = "NS"
#   ttl     = "300"
#   records = [
#     "demi.ns.cloudflare.com",
#     "peyton.ns.cloudflare.com"
#   ]
# }

########################################################################
############################# DO NOT TOUCH #############################
########################################################################
# This record is a TEMPORARY record for ACM validation
# resource "aws_route53_record" "TEMPORARY_record" {
#   zone_id = aws_route53_zone.public.zone_id
#   name    = "fleet.${var.public_domain}"
#   type    = "A"
#   records = ["172.16.1.1"]
# }

# This creates an SSL certificate
resource "aws_acm_certificate" "myapp" {
  domain_name       = aws_route53_record.myapp.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Team = var.team
  }
}

# This is a DNS record for the ACM certificate validation to prove we own the domain
#
# This example, we make an assumption that the certificate is for a single domain name so can just use the first value of the
# domain_validation_options.  It allows the terraform to apply without having to be targeted.
# This is somewhat less complex than the example at https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
# - that above example, won't apply without targeting

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.public_domain.id
  ttl             = 60
  # depends_on = [
  #   aws_route53_record.TEMPORARY_record,
  # ]
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.myapp.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
  depends_on = [
    #aws_route53_record.TEMPORARY_record,
    aws_db_instance.fleet_mysql_server,
    aws_elasticache_cluster.fleet_redis,
    aws_ecs_task_definition.fleet_ecs_web
  ]
}

# Standard route53 DNS record for "myapp" pointing to an ALB
resource "aws_route53_record" "myapp" {
  zone_id = data.aws_route53_zone.public_domain.zone_id
  name    = "fleet.${data.aws_route53_zone.public_domain.name}"
  type    = "A"
  alias {
    name                   = aws_alb.main.dns_name
    zone_id                = aws_alb.main.zone_id
    evaluate_target_health = false
  }
}


################################################### Internal domain ###################################################
resource "aws_route53_zone" "internal_domain" {
  name = var.internal_domain

  vpc {
    vpc_id = aws_vpc.fleet_vpc.id
  }
  
  tags = {
    Name = "${var.FLEET_PREFIX}_route53_private_zone"
    Team = var.team
  }
}

resource "aws_route53_record" "mysql_server" {
  zone_id = aws_route53_zone.internal_domain.zone_id
  name    = "mysql.${var.internal_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_db_instance.fleet_mysql_server.endpoint]
}

resource "aws_route53_record" "redis_server" {
  zone_id = aws_route53_zone.internal_domain.zone_id
  name    = "redis.${var.internal_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_elasticache_cluster.fleet_redis.cache_nodes.0.address]
}

# resource "aws_route53_record" "fleet_servers" {
#   zone_id = aws_route53_zone.internal_domain.zone_id
#   name    = "fleetXX.${var.internal_domain}"
#   type    = "CNAME"
#   ttl     = "60"
#   records = [<ecs01>,<ecs02>,<ecs03>]
# }