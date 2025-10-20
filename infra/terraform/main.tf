# ============================================================================
# TERRAFORM & PROVIDER CONFIGURATION
# ============================================================================

terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ============================================================================
# VPC & NETWORKING
# ============================================================================

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Project                                     = var.cluster_name
    Env                                         = var.env
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.cluster_name}-igw"
    Project = var.cluster_name
    Env     = var.env
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.cluster_name}-public-rt"
    Project = var.cluster_name
    Env     = var.env
  }
}

# Subnet A (us-east-1a)
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-subnet-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.cluster_name
    Env                                         = var.env
  }
}

# Subnet B (us-east-1b)
resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-subnet-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.cluster_name
    Env                                         = var.env
  }
}

# Route Table Association - Subnet A
resource "aws_route_table_association" "subnet_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

# Route Table Association - Subnet B
resource "aws_route_table_association" "subnet_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# EKS CLUSTER
# ============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.29.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  # Managed node groups
  eks_managed_node_groups = {
    default = {
      desired_size   = var.node_desired
      min_size       = var.node_min
      max_size       = var.node_max
      instance_types = [var.node_type]

      # SSH key for node access
      key_name = var.ssh_key_name

      # Use both subnets for high availability
      subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

      # Node tags
      tags = {
        Name    = "${var.cluster_name}-node"
        Env     = var.env
        Project = var.cluster_name
      }
    }
  }

  # Cluster tags
  tags = {
    Project = var.cluster_name
    Env     = var.env
  }
}

# ============================================================================
# ECR REPOSITORY
# ============================================================================

resource "aws_ecr_repository" "app" {
  name                 = "ship-a-service"
  image_tag_mutability = "MUTABLE"

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable encryption at rest
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.env
    Project     = var.cluster_name
  }
}

# ECR Lifecycle Policy (optional - keeps last 10 images)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================================================
# IAM ROLES FOR CI/CD (GitHub Actions OIDC)
# ============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Project = var.cluster_name
    Env     = var.env
  }
}

# GitHub Actions OIDC provider (must exist in your AWS account)

# IAM role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${var.cluster_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn

        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Allow any branch/tag in your repository
            "token.actions.githubusercontent.com:sub" = "repo:MarzouguiAhmed9/ship-a-service-end-to-end-ci-cd-on-managed-kubernetes:*"
          }
        }
      }
    ]
  })

  tags = {
    Project = var.cluster_name
    Env     = var.env
    TTL     = "7d" # optional time-to-live

  }
}

# Attach ECR PowerUser policy (push/pull images)
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Custom policy for EKS access (more restrictive than AmazonEKSClusterPolicy)
resource "aws_iam_policy" "eks_deploy_policy" {
  name        = "${var.cluster_name}-eks-deploy-policy"
  description = "Policy for GitHub Actions to deploy to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:AccessKubernetesApi"
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })

  tags = {
    Project = var.cluster_name
    Env     = var.env
  }
}

# Attach custom EKS policy
resource "aws_iam_role_policy_attachment" "eks_deploy_access" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.eks_deploy_policy.arn
}