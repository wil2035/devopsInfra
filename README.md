# AWS Infrastructure Setup

This code defines an infrastructure setup for AWS cloud. It creates a Virtual Private Cloud (VPC) along with two subnets in different availability zones, a security group, an internet gateway, an Application Load Balancer (ALB), and an API Gateway with necessary resources.

## Prerequisites

AWS account with appropriate access credentials.
Terraform installed on the local machine.

## Usage
  1. Clone the repository.
  2. Navigate to the directory containing the code.
  3. Run terraform init to initialize the backend and download required plugins.
  4. Run terraform apply to deploy the infrastructure.
  5. Once the infrastructure is deployed, run terraform destroy to destroy the infrastructure.

## Resources
* **aws_vpc** - creates a VPC with CIDR block 10.0.0.0/16.
* **aws_subnet** - creates two subnets, one in each of the two availability zones (us-east-1a and us-east-1b) with CIDR blocks 10.0.1.0/24 and 10.0.2.0/24.
* **aws_security_group** - creates a security group that allows incoming traffic on port 80.
* **aws_instance** - creates two EC2 instances of type t2.micro with an Ubuntu Server 20.04 LTS (HVM) AMI (ami-06e46074ae430fba6) and associates them with the previously created subnet. It also installs and configures the microservice with the user_data script.
* **aws_internet_gateway** - creates an internet gateway and associates it with the VPC.
* **aws_lb** - creates an Application Load Balancer with the name microservice-lb and associates it with the previously created subnets and security group.
* **aws_lb_target_group** - creates an ALB target group with a prefix msrvtg and associates it with the previously created VPC.
* **aws_api_gateway_rest_api** - creates an API Gateway REST API with the name microservice_api.
* **aws_api_gateway_resource** - creates a resource under the previously created REST API with the path devops.
* **aws_api_gateway_method** - creates an HTTP POST method under the previously created resource with authorization set to JWT.
* **aws_api_gateway_integration** - creates an HTTP integration for the previously created method and associates it with the Application Load Balancer.
* **aws_api_gateway_method_response** - creates a method response for the previously created method with a status code 200.
* **aws_api_gateway_integration_response** - creates an integration response for the previously created integration.

## Variables

* **region** - sets the region for the infrastructure setup. Default value is us-east-1.
* **ami_id** - sets the ID of the Amazon Machine Image (AMI) to use for the EC2 instance. Default value is ami-06e46074ae430fba6.
* **instance_type** - sets the type of the EC2 instance. Default value is t2.micro.
* **port** - sets the port for the security group. Default value is 80.
* **cidr_block** - sets the CIDR block for the VPC. Default value is 10.0.0.0/16.
* **subnet_cidr_a** - sets the CIDR block for the first subnet. Default value is 10.0.1.0/24.
* **subnet_cidr_b** - sets the CIDR block for the second subnet. Default value is 10.0.2.0/24.