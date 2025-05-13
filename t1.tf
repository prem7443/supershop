terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}



provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# New VPC + Subnet + Networking
# ---------------------------
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "172.17.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ecs-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "172.17.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

# ---------------------------
# Security Group (in the new VPC)
# ---------------------------
resource "aws_security_group" "ecs_sg" {
  name   = "ecs_sg"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all IPs for port 8000
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# ---------------------------
# CloudWatch Logs
# ---------------------------
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-task-logs"
  retention_in_days = 7
}

# ---------------------------
# IAM Roles
# ---------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ---------------------------
# ECS Cluster
# ---------------------------
resource "aws_ecs_cluster" "cluster" {
  name = "my-cluster"
}

# ---------------------------
# Task Definition (for Fargate) with new image
# ---------------------------
resource "aws_ecs_task_definition" "task" {
  family                   = "my-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "my-container"
    image     = "354912177173.dkr.ecr.us-east-1.amazonaws.com/repo1"  # Updated image
    essential = true
    portMappings = [{
      containerPort = 8000,
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name,  # Reference created log group
        awslogs-region        = "us-east-1",
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# ---------------------------
# Network Load Balancer (NLB) with new VPC
# ---------------------------
resource "aws_lb" "nlb1" {
  name               = "nlb1"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]
}

resource "aws_lb_target_group" "nlb1_tg" {
  name        = "nlb1-tg"
  port        = 8000
  protocol    = "TCP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = "8000"
  }
}

resource "aws_lb_listener" "nlb1_listener" {
  load_balancer_arn = aws_lb.nlb1.arn
  port              = 8000
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb1_tg.arn
  }
}

# ---------------------------
# ECS Service (Fargate) with new VPC
# ---------------------------
resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nlb1_tg.arn
    container_name   = "my-container"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.nlb1_listener
  ]
}

# ---------------------------
# API Gateway - REST API
# ---------------------------
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api"
  description = "API for accessing ECS service via NLB"
}

# ---------------------------
# Root Resource (for accessing ECS service)
# ---------------------------
resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "myservice"  # Example path
}

# ---------------------------
# Method for the API - HTTP (GET or POST depending on your use case)
# ---------------------------
resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "GET"  # Use "POST" if needed
  authorization = "NONE"
}

# ---------------------------
# Integration with NLB - API Gateway to NLB
# ---------------------------
resource "aws_api_gateway_integration" "nlb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.my_method.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.nlb1.dns_name}:8000"  # Point to your NLB DNS and port

  # Optional: You can add request/response mappings if needed
}

# ---------------------------
# Method Response (optional)
# ---------------------------
resource "aws_api_gateway_method_response" "my_method_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.my_method.http_method
  status_code = "200"
}


# ---------------------------
# Deploy the API
# ---------------------------
resource "aws_api_gateway_deployment" "my_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "ssss"  # You can change this to your desired stage
  depends_on = [
    aws_api_gateway_integration.nlb_integration,
    aws_api_gateway_method.my_method
  ]
}

# ---------------------------
# Outputs
# ---------------------------
output "nlb_dns" {
  value = aws_lb.nlb1.dns_name
}

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.my_api_deployment.invoke_url}/myservice"
}
