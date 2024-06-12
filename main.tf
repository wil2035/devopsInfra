provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "microservice_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "microservice_vpc"
  }
}

resource "aws_subnet" "microservice_subnet_a" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.microservice_vpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "microservice_subnet_a"
  }
}

resource "aws_subnet" "microservice_subnet_b" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.microservice_vpc.id
  availability_zone = "us-east-1b"

  tags = {
    Name = "microservice_subnet_b"
  }
}


resource "aws_security_group" "microservice_sg" {
  name_prefix = "microservice_sg_"
  vpc_id = aws_vpc.microservice_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "microservice" {
  ami           = "ami-06e46074ae430fba6"
  instance_type = "t2.micro"
  count         = 2
  subnet_id     = aws_subnet.microservice_subnet_a.id

  tags = {
    Name = "microservice-${count.index}"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Install and configure your microservice here
              sudo yum update -y
              sudo amazon-linux-extras install docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              docker info

              EOF

  vpc_security_group_ids = [aws_security_group.microservice_sg.id]
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.microservice_vpc.id
}

resource "aws_lb" "microservice-lb" {
  name               = "microservice-lb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.microservice_subnet_a.id,
    aws_subnet.microservice_subnet_b.id,
  ]

  security_groups = [aws_security_group.microservice_sg.id]

  tags = {
    Name = "microservice-lb"
  }

  depends_on = [
    aws_instance.microservice,
  ]
}

resource "aws_lb_target_group" "microservice_tg" {
  name_prefix = "msrvtg"

  port     = 80
  protocol = "HTTP"

  target_type = "instance"

  health_check {
    path = "/health"
  }

  vpc_id = aws_vpc.microservice_vpc.id
}

resource "aws_api_gateway_rest_api" "microservice_api" {
  name = "microservice_api"
}

resource "aws_api_gateway_resource" "microservice_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  parent_id   = aws_api_gateway_rest_api.microservice_api.root_resource_id
  path_part   = "devops"
}

resource "aws_api_gateway_method" "microservice_method" {
  rest_api_id   = aws_api_gateway_rest_api.microservice_api.id
  resource_id   = aws_api_gateway_resource.microservice_resource.id
  http_method   = "POST"
  authorization = "JWT"
}

resource "aws_api_gateway_integration" "microservice_integration" {
  rest_api_id             = aws_api_gateway_rest_api.microservice_api.id
  resource_id             = aws_api_gateway_resource.microservice_resource.id
  http_method             = aws_api_gateway_method.microservice_method.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "${aws_lb.microservice-lb.dns_name}/devops"
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# Configure method response
resource "aws_api_gateway_method_response" "devops_method_response" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method.http_method
  status_code = "200"
}

# Configure integration response
resource "aws_api_gateway_integration_response" "devops_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method.http_method
  status_code = aws_api_gateway_method_response.devops_method_response.status_code
}

resource "aws_ecr_repository" "microservice" {
  name = "microservice"
}