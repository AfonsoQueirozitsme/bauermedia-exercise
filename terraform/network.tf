# 1. VPC
resource "aws_vpc" "k3s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k3s-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "k3s_igw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

# 3. Route Table
resource "aws_route_table" "k3s_rt" {
  vpc_id = aws_vpc.k3s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s_igw.id
  }

  tags = {
    Name = "k3s-route-table"
  }
}

# 4. Subnets (2 AZs required for ALB)
resource "aws_subnet" "k3s_subnet_a" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-a"
  }
}

resource "aws_subnet" "k3s_subnet_b" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "k3s-subnet-b"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.k3s_subnet_a.id
  route_table_id = aws_route_table.k3s_rt.id
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.k3s_subnet_b.id
  route_table_id = aws_route_table.k3s_rt.id
}

# 6. Security Group
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "Security group for K3s cluster"
  vpc_id      = aws_vpc.k3s_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-sg"
  }
}

# 7. Application Load Balancer
resource "aws_lb" "k3s_alb" {
  name               = "k3s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k3s_sg.id]
  subnets            = [aws_subnet.k3s_subnet_a.id, aws_subnet.k3s_subnet_b.id]

  tags = {
    Name = "k3s-alb"
  }
}

resource "aws_lb_target_group" "k3s_tg" {
  name     = "k3s-tg"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = aws_vpc.k3s_vpc.id

  health_check {
    path                = "/"
    port                = "30080"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }

  tags = {
    Name = "k3s-tg"
  }
}

resource "aws_lb_target_group_attachment" "master" {
  target_group_arn = aws_lb_target_group.k3s_tg.arn
  target_id        = aws_instance.k3s_master.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "worker" {
  target_group_arn = aws_lb_target_group.k3s_tg.arn
  target_id        = aws_instance.k3s_worker.id
  port             = 30080
}

resource "aws_lb_listener" "k3s_listener" {
  load_balancer_arn = aws_lb.k3s_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_tg.arn
  }
}
