provider "aws" {
  region = "us-west-2"
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}


resource "aws_subnet" "web" {
  count = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mongo" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_docdb_cluster" "mongo" {
  cluster_identifier      = "mongo-cluster"
  master_password         = jsondecode(data.aws_secretsmanager_secret_version.mongo_password.secret_string)["password"]
  master_username         = "admin"
  skip_final_snapshot     = true
  engine                  = "docdb"
  engine_version          = "4.0.0"
  backup_retention_period = 7
  preferred_backup_window = "00:00-00:30"
  preferred_maintenance_window = "sun:06:00-sun:06:30"
}

data "aws_secretsmanager_secret_version" "mongo_password" {
  secret_id = aws_secretsmanager_secret.mongo_password.id
}
resource "aws_docdb_cluster_instance" "mongo_instance" {
  count                  = 2
  cluster_identifier     = aws_docdb_cluster.mongo.id
  instance_class         = "db.r5.large"
  engine                 = "docdb"
  engine_version         = "4.0.0"
  publicly_accessible    = false
}

# Create EC2 Instances for Frontend and Backend Web Servers
resource "aws_instance" "frontend" {
  count         = 2
  ami           = "ami-12345678" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.web[count.index].id
  security_groups = [aws_security_group.web.name]
}

resource "aws_instance" "backend" {
  count         = 2
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.web[count.index].id
  security_groups = [aws_security_group.web.name]
}

# Provision Load Balancer (Classic ELB)
resource "aws_elb" "web" {
  availability_zones = data.aws_availability_zones.available.names
  listeners {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
  instances = concat(aws_instance.frontend[*].id, aws_instance.backend[*].id)
}

# Create Auto Scaling Group for Web Servers
resource "aws_launch_configuration" "web" {
  name          = "web-launch-configuration"
  instance_type = "t2.micro"
  image_id      = "ami-12345678"
}

resource "aws_autoscaling_group" "web" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = aws_subnet.web[*].id
  launch_configuration = aws_launch_configuration.web.name
}

# Fetch Availability Zones dynamically
data "aws_availability_zones" "available" {}

# Secure MongoDB Password in Secrets Manager 
resource "aws_secretsmanager_secret" "mongo_password" {
  name        = "mongo-cluster-password"
  description = "MongoDB cluster master password"
}

