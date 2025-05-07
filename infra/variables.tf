variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project which would be used as prefix of resources"
  type        = string
  default     = "final"
}

variable "eks_cluster_iam_role_name" {
  description = "Name of the pre-existing IAM role for EKS cluster"
  type        = string
  default     = "LabRole"
}

variable "eks_node_group_iam_role_name" {
  description = "Name of the pre-existing IAM role for worker nodes"
  type        = string
  default     = "LabRole"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "node_instance_type" {
  description = "Worker node instance type"
  type        = string
  default     = "t3.large"
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "myapp"
}

variable "mysql_username" {
  description = "MySQL database username"
  type        = string
  default     = "root"
}

variable "mysql_password" {
  description = "MySQL database password"
  type        = string
  default     = "password"
}

variable "mysql_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.medium"
}
