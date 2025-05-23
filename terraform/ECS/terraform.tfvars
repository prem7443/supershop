region                    = "us-east-1"                # AWS region for deployment
vpc_name                  = "vpc1"        # Name of the VPC
subnet_name               = "sub1"  # Name of the public subnet
port                      = 8000                        # Port for ECS container and NLB
image                     = "354912177173.dkr.ecr.us-east-1.amazonaws.com/repo1"  # Docker image for ECS container
launch_type               = "FARGATE"                   # Launch type (FARGATE or EC2)
desired_count             = 1                           # Desired number of ECS tasks
cluster_name              = "cl"         # Name of the ECS Cluster
nlb_name                  = "nlb1"             # Name of the Network Load Balancer
api_name                  = "demoapi"             # Name of the API Gateway
new_endpoint_path         = "api/new-endpoint"          # Path for the new endpoint
new_method                = "GET"                       # HTTP method for the new endpoint
health_check_grace_period_seconds = 60                  # Grace period for ECS service health check
api_stage                 = "dev"
task_cpu                  =   256
task_memory               = 512  
secret_name         = "sec118899"                        
razorpay_key_id     = "hgfvhjhhj"
razorpay_key_secret = "chffhkftf"

db_name     = "mydatabase"
db_user     = "dkfyf"
db_password = "bvgfcnhg"



