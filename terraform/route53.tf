################################################### Public domain ###################################################
# resource "aws_acm_certificate" "fleet_public_cert" {
#   domain_name       = "fleet.${var.public_domain}"
#   validation_method = "DNS"

#   tags = {
#     Name = "${var.FLEET_PREFIX}_public_cert"
#     Team = var.team
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_zone" "public_domain" {
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
#   ttl     = "300"
#   records = <ELB>
# }

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