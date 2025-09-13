variable "project_prefix" { type = string }
variable "environment"    { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type"  { type = string }
variable "alb_sg_id"      { type = string }
variable "ec2_sg_id"      { type = string }
variable "user_data_env_label" { type = string }
variable "lb_target_group_arn" { type = string }


data "aws_ami" "amazonlinux" {
  owners      = ["137112412989"] # Amazon
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_prefix}-${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_prefix}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.project_prefix}-${var.environment}-lt-"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = var.instance_type
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(<<EOT
#!/bin/bash
set -eux
dnf update -y
dnf install -y nginx
cat >/usr/share/nginx/html/index.html <<'EOF'
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Gopi Capstone - ${var.environment}</title></head>
  <body style="font-family: sans-serif; padding:40px;">
    <h1>Welcome to Gopi Capstone - ${var.user_data_env_label}</h1>
    <p>This environment is <b>${var.environment}</b>.</p>
  </body>
</html>
EOF
systemctl enable nginx
systemctl start nginx
EOT
  )
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.project_prefix}-${var.environment}-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_prefix}-${var.environment}-web"
    propagate_at_launch = true
  }
}

# Attach the ASG to the ALB Target Group so traffic reaches instances
resource "aws_autoscaling_attachment" "asg_to_tg" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn   = var.lb_target_group_arn
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

