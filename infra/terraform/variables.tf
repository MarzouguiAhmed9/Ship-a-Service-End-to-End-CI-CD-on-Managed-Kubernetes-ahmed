# AWS region sotkholm
variable "region" {
  description = "AWS region for resources"
  default     = "eu-north-1"  
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# Subnet CIDRs
variable "subnet_a_cidr" {
  description = "CIDR block for subnet A"
  default     = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for subnet B"
  default     = "10.0.2.0/24"
}

# Availability zones
variable "az_a" {
  description = "Availability Zone A"
  default     = "eu-north-1a"
}

variable "az_b" {
  description = "Availability Zone B"
  default     = "eu-north-1b"
}



# eks variable
 variable "cluster_name" { default = "ship-a-service" }
variable "env"         { default = "dev" }
variable "node_type"   { default = "t3.medium" }   
variable "node_min"    { default = 1 }
variable "node_desired"{ default = 1 }
variable "node_max"    { default = 2 }
variable "ssh_key_name"{ default = "ahmedkey" }          
