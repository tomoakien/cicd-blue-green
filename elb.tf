#ALBの追加
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
}

#ALBリスナー追加
resource "aws_lb_listener" "http80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "http9000" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 9000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

#ターゲットグループ作成
resource "aws_lb_target_group" "blue" {
  name     = "blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  #fargateを指定する場合ipを指定
  target_type = "ip"
}

#ターゲットグループ作成
resource "aws_lb_target_group" "green" {
  name     = "green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  #fargateを指定する場合ipを指定
  target_type = "ip"
}
