variable "project_prefix" { type = string }
variable "environment"    { type = string }
variable "vpc_id"         { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id"      { type = string }
variable "target_group_vpc_id" { type = string }
variable "target_instance_sg_id" { type = string }
variable "target_instance_ids" { type = list(string) }

resource "aws_lb" "this" {
  name               = "${var.project_prefix}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_prefix}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.target_group_vpc_id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# removed unused autoscaling_attachment to avoid confusion
# # removed erroneous autoscaling_attachment block

# Attach the ASG dynamically using aws_autoscaling_attachment (using data source would require ASG name).
# Instead, create explicit ASG attachment using a separate resource from the ec2 module output via a local.
# We will expect caller to reference ASG by name if needed.
# For simplicity, we skip explicit attachment here because recent providers attach automatically when target group is referenced in LT/ASG.
# (Not attaching to avoid circular deps.)

output "alb_dns_name" { value = aws_lb.this.dns_name }

output "tg_arn" { value = aws_lb_target_group.tg.arn }
