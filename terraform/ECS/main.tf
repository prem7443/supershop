# ---------------------------
# Provider Configuration
# ---------------------------
provider "aws" {
  region = var.region  # User-defined region
}



# ---------------------------
# VPC + Subnet + Networking
# ---------------------------
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "172.17.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "172.17.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = var.subnet_name
  }
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
# CloudWatch Logs
# ---------------------------
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-task-logs"
  retention_in_days = 7
}

# ---------------------------
# IAM Roles for ECS
# ---------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
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

resource "aws_iam_role_policy_attachment" "ecs_secrets_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# ---------------------------
# Razorpay Secrets in Secrets Manager
# ---------------------------
# ---------------------------
# Razorpay Secrets Manager
# ---------------------------
resource "aws_secretsmanager_secret" "razorpay_secret" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "razorpay_secret_version" {
  secret_id     = aws_secretsmanager_secret.razorpay_secret.id
  secret_string = jsonencode({
    razorpay_key_id     = var.razorpay_key_id,
    razorpay_key_secret = var.razorpay_key_secret
  })
}



# ---------------------------
# Security Group
# ---------------------------
resource "aws_security_group" "ecs_sg" {
  name   = "ecs_sg"
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_sg"
  }
}


# ---------------------------
# ECS Cluster
# ---------------------------
resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name

  tags = {
    Name        = var.cluster_name
    Environment = var.api_stage
  }
}

# ---------------------------
# ECS Task Definition
# ---------------------------
resource "aws_ecs_task_definition" "task" {
  family                   = "my-task"
  requires_compatibilities = [var.launch_type]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "my-container"
    image     = var.image
    essential = true
    portMappings = [{
      containerPort = var.port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name,
        awslogs-region        = var.region,
        awslogs-stream-prefix = "ecs"
      }
    }
    secrets = [
      {
        name      = "RAZORPAY_KEY_ID"
        valueFrom = "${aws_secretsmanager_secret.razorpay_secret.arn}:razorpay_key_id::"
      },
      {
        name      = "RAZORPAY_KEY_SECRET"
        valueFrom = "${aws_secretsmanager_secret.razorpay_secret.arn}:razorpay_key_secret::"
      }
    ]
  }])
}


# ---------------------------
# Network Load Balancer (NLB)
# ---------------------------
resource "aws_lb" "nlb1" {
  name               = var.nlb_name
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_subnet.id]
}

resource "aws_lb_target_group" "nlb1_tg" {
  name        = "nlb1-tg"
  port        = var.port
  protocol    = "TCP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = var.port
  }
}

resource "aws_lb_listener" "nlb1_listener" {
  load_balancer_arn = aws_lb.nlb1.arn
  port              = var.port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb1_tg.arn
  }
}

# ---------------------------
# ECS Service
# ---------------------------
resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nlb1_tg.arn
    container_name   = "my-container"
    container_port   = var.port
  }

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

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
