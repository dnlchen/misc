# Extenal NLB
resource "aws_eip" "this" {
  for_each = toset(var.subnets_public)
  vpc      = true

  tags = merge(
    var.tags_common,
    {
      "Name"    = "${var.env}-nlb-ext-eip"
      "service" = var.tag_service
    }
  )
}

resource "aws_lb" "external" {
  name               = "${var.env}-nlb-ext"
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = var.subnets_public

    content {
      subnet_id     = subnet_mapping.value
      allocation_id = aws_eip.this[subnet_mapping.value].id
    }
  }

  access_logs {
    bucket  = var.elb_access_logs_bucket_name
    prefix  = "${var.env}-nlb-ext"
    enabled = true
  }

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true
  internal                         = false

  tags = merge(
    var.tags_common,
    {
      "Name"    = "${var.env}-nlb-ext"
      "service" = var.tag_project
    }
  )
}

resource "aws_lb_target_group" "proxy_ext" {
  name     = "${var.env}-tg-ext"
  port     = var.http_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  tags = merge(
    var.tags_common,
    {
      "Name"    = "${var.env}-tg-ext"
      "service" = var.tag_project
    }
  )
}

resource "aws_lb_listener" "proxy_ext" {
  load_balancer_arn = aws_lb.external.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.backend_elb_cert_iam_id

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.proxy_ext.arn
  }
}

# Add instances to target group
resource "aws_lb_target_group_attachment" "backend_ext" {
  target_group_arn = aws_lb_target_group.proxy_ext.arn
  count            = var.backend_nodes_qty
  target_id        = element(aws_instance.backend.*.id, count.index)
  port             = var.http_port
}
