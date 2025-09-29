
locals {
  # Create certificates for BOTH environments at the same time
  certs = {
    prod = {
      primary = "${var.prod_subdomain}.${var.root_domain}"
    }
    staging = {
      primary = "${var.staging_subdomain}.${var.root_domain}"
    }
  }
}

resource "aws_acm_certificate" "ingress" {
  for_each          = local.certs
  domain_name       = each.value.primary
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Environment = each.key
    Name        = "${var.project}-${each.key}-certificate"
  })
}

resource "aws_route53_record" "certificate_validation" {
  # Create one DNS record per certificate (each cert currently has a single validation option)
  for_each = {
    for item in flatten([
      for key, cert in aws_acm_certificate.ingress : [
        for dvo in cert.domain_validation_options : {
          id    = "${key}-${dvo.resource_record_name}"
          key   = key
          name  = dvo.resource_record_name
          type  = dvo.resource_record_type
          value = dvo.resource_record_value
        }
      ]
    ]) : item.id => item
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "ingress" {
  for_each = aws_acm_certificate.ingress

  certificate_arn = each.value.arn
  validation_record_fqdns = [
    for r in aws_route53_record.certificate_validation : r.fqdn
    if r.value.key == each.key
  ]
}
