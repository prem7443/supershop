# ---------------------------
# Variables
# ---------------------------
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "ecs-vpc"
}

variable "subnet_name" {
  description = "Name of the public subnet"
  type        = string
  default     = "ecs-public-subnet"
}

variable "port" {
  description = "Port for ECS container and NLB"
  type        = number
  default     = 80
}

variable "image" {
  description = "Docker image for the ECS container"
  type        = string
  default     = "nginx"  # Default image can be updated as needed
}

variable "launch_type" {
  description = "Launch type for ECS service (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
  default     = "my-ecs-cluster"
}

variable "nlb_name" {
  description = "Name of the Network Load Balancer"
  type        = string
  default     = "my-nlb"
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "my-api"
}

variable "new_endpoint_path" {
  description = "Path for the new endpoint"
  type        = string
  default     = "new-endpoint"
}

variable "new_method" {
  description = "HTTP method for the new endpoint (GET, POST, etc.)"
  type        = string
  default     = "GET"
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for ECS service health check in seconds"
  type        = number
  default     = 60
}

variable "api_stage" {
  description = "Stage name for the API Gateway"
  type        = string
  default     = "dev"
}

variable "task_cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for ECS task"
  type        = string
  default     = "512"
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
  default     = "sec12"
}

variable "razorpay_key_id" {
  description = "Razorpay API Key ID"
  type        = string
  sensitive   = true
}

variable "razorpay_key_secret" {
  description = "Razorpay API Secret Key"
  type        = string
  sensitive   = true
}


variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_user" {
  description = "The database user"
  type        = string
}

variable "db_password" {
  description = "The database password"
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "container_name" {
  description = "Name of the container in ECS"
  type        = string
}

variable "image_url" {
  description = "URL of the Docker image in ECR"
  type        = string
}
