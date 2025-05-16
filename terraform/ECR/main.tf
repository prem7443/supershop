# AWS Region (Already defined in your variables)
provider "aws" {
  region = var.region
}

# Create ECR Repository
resource "aws_ecr_repository" "my_repository" {
  name                 = var.ecr_repo_name  # Use user input for ECR repo name
  image_tag_mutability = "MUTABLE"  
  tags = {
    Name = "ECR Repo"
    Environment = "Production"  
  }
}

# Output the repository URL
output "ecr_repo_url" {
  value = aws_ecr_repository.my_repository.repository_url
}
