locals {
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
  for_each = aws_acm_certificate.ingress

  zone_id = var.route53_zone_id

  name = tolist(each.value.domain_validation_options)[0].resource_record_name
  type = tolist(each.value.domain_validation_options)[0].resource_record_type
  ttl  = 60
  records = [
    tolist(each.value.domain_validation_options)[0].resource_record_value
  ]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "ingress" {
  for_each = aws_acm_certificate.ingress

  certificate_arn = each.value.arn
  validation_record_fqdns = [
    aws_route53_record.certificate_validation[each.key].fqdn
  ]
}
