resource "aws_security_group" "app" {
  name        = "sg"
  description = "sg"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "http_in" {
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "out" {
  security_group_id = aws_security_group.app.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

#alb用のセキュリティグループ
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "alb-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "alb-sg"
  }
}

#albのinは全て受け入れる
resource "aws_security_group_rule" "alb_tcp_in80" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [local.any_cidr]
}

resource "aws_security_group_rule" "alb_tcp_in9000" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = [local.my_global_ip]
}

#albのoutはserviceにoutする
resource "aws_security_group_rule" "alb_tcp_out" {
  security_group_id        = aws_security_group.alb.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}
