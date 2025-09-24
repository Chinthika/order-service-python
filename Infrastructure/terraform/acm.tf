locals {
  acm_primary_domain = var.environment == "prod" ? "${var.prod_subdomain}.${var.root_domain}" : "${var.staging_subdomain}.${var.root_domain}"
  acm_sans           = var.environment == "prod" ? [var.root_domain] : []
}

resource "aws_acm_certificate" "ingress" {
  domain_name               = local.acm_primary_domain
  validation_method         = "DNS"
  subject_alternative_names = local.acm_sans

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-certificate"
  })
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in aws_acm_certificate.ingress.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "ingress" {
  certificate_arn         = aws_acm_certificate.ingress.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}
