data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

output "name_servers" {
  value = aws_route53_zone.this.name_servers
}

resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "backend" {
  name                 = "backend"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "background" {
  name                 = "background"
  image_tag_mutability = "MUTABLE"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }

  tags = {
    Terraform = "true"
  }
}

resource "aws_security_group" "ec2" {
  name   = "${var.project_name}-ec2"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "server_qa" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.node_instance_type
  key_name                    = "aws"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  tags = {
    Name = "server-qa"
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
}

resource "aws_instance" "server_uat" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.node_instance_type
  key_name                    = "aws"
  subnet_id                   = module.vpc.public_subnets[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  tags = {
    Name = "server-uat"
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_nodes" {
  name   = "${var.project_name}-node"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-db"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.mysql_instance_class
  db_name                 = var.mysql_database
  username                = var.mysql_username
  password                = var.mysql_password
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  backup_retention_period = 0
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-kluster"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_cluster_iam_role_name}"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
    security_group_ids = [
      aws_security_group.eks_cluster.id,
      aws_security_group.eks_nodes.id
    ]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "nodes"
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.eks_node_group_iam_role_name}"
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 4
    max_size     = 5
    min_size     = 3
  }

  instance_types = [var.node_instance_type]

  depends_on = [
    aws_eks_cluster.this,
  ]
}
