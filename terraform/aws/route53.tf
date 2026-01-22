resource "aws_route53_zone" "idp" {
  name = var.domain
  tags = local.common_tags
}

resource "aws_route53_record" "idp_A" {
  zone_id = aws_route53_zone.idp.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.idp.dns_name
    zone_id                = aws_lb.idp.zone_id
    evaluate_target_health = false
  }
}
