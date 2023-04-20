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

  tags = {
    Name = "microservice_subnet_a"
  }
}

resource "aws_subnet" "microservice_subnet_b" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.microservice_vpc.id

  tags = {
    Name = "microservice_subnet_b"
  }
}


resource "aws_security_group" "microservice_sg" {
  name_prefix = "microservice_sg_"

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
              EOF

  vpc_security_group_ids = [aws_security_group.microservice_sg.id]
}


resource "aws_lb" "microservice_lb" {
  name               = "microservice_lb"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.microservice_subnet_a.id,
    aws_subnet.microservice_subnet_b.id,
  ]

  security_groups = [aws_security_group.microservice_sg.id]

  tags = {
    Name = "microservice_lb"
  }

  depends_on = [
    aws_instance.microservice,
  ]
}

resource "aws_lb_target_group" "microservice_tg" {
  name_prefix = "microservice_tg_"

  port     = 80
  protocol = "HTTP"

  target_type = "instance"

  health_check {
    path = "/health"
  }

  vpc_id = aws_vpc.microservice_vpc.id
}

resource "aws_api_gateway_rest_api" "miapi_gatecroservice_api" {
  name = "microservice_api"
}

resource "aws_api_gateway_resource" "microservice_resource" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  parent_id   = aws_api_gateway_rest_apapi_gatei.microservice_api.root_resource_id
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
  uri                     = "${aws_lb.microservice_lb.dns_name}/devops"
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# Configure method response
resource "aws_api_gateway_method_response" "devops_method_response" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method.http_method

  # Response headers
  response_models = {
    "application/json" = "Empty"
  }
}

# Configure integration response
resource "aws_api_gateway_integration_response" "devops_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.microservice_api.id
  resource_id = aws_api_gateway_resource.microservice_resource.id
  http_method = aws_api_gateway_method.microservice_method.http_method

  # Response headers
  response_templates = {
    "application/json" = ""
  }
}