############################# Create RDS ##############################
resource "random_password" "database_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "database_password_secret" {
  name = "/fleet/database/password/master"
}

resource "aws_secretsmanager_secret_version" "database_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.database_password_secret.id
  secret_string = random_password.database_password.result
}

resource "aws_security_group" "mysql_sg" {
  name        = "${var.FLEET_PREFIX}_mysql_sg"
  description = "Allow Fleet to access MySQL"
  vpc_id      = aws_vpc.fleet_vpc.id

  ingress {
    description      = "Allow access to MySQL"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.fleet_private_a_subnet.cidr_block,
      aws_subnet.fleet_private_b_subnet.cidr_block
    ]
  }

  tags = {
    Name = "${var.FLEET_PREFIX}_mysql_sg"
    Team = var.team
  }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "fleet-mysql-subnet-group"
  subnet_ids = [
    aws_subnet.fleet_private_a_subnet.id, 
    aws_subnet.fleet_private_b_subnet.id
  ]
}        

resource "aws_db_instance" "fleet_mysql_server" {
  publicly_accessible     = false
  identifier              = "fleet"
  #availability_zone       = var.availability_zone
  allocated_storage       = 10
  engine                  = "mysql"
  engine_version          = "8.0.25"
  instance_class          = "db.t3.micro"
  name                    = "fleet"
  username                = "fleet"   
  password                = random_password.database_password.result
  skip_final_snapshot     = true
  multi_az                = false
  parameter_group_name    = "default.mysql8.0"
  vpc_security_group_ids  = [aws_security_group.mysql_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.mysql_subnet_group.name

  tags = {
    Name = "${var.FLEET_PREFIX}_MYSQL_database"
    Team = var.team
  }
}

############################## Create Redis ##############################
resource "aws_security_group" "redis_sg" {
  name        = "${var.FLEET_PREFIX}_redis_sg"
  description = "Allow Fleet to access Redis"
  vpc_id      = aws_vpc.fleet_vpc.id

  ingress {
    description      = "Allow access to Redis"
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.fleet_private_a_subnet.cidr_block,
      aws_subnet.fleet_private_b_subnet.cidr_block
    ]
  }

  tags = {
    Name = "${var.FLEET_PREFIX}_redis_sg"
    Team = var.team
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "fleet-redis-subnet-group"
  subnet_ids = [
    aws_subnet.fleet_private_a_subnet.id, 
    aws_subnet.fleet_private_b_subnet.id
  ]
}        

resource "aws_elasticache_cluster" "fleet_redis" {
  cluster_id           = "${replace(join("",[lower(var.FLEET_PREFIX), "_redis"]), "_", "-")}"
  availability_zone    = var.availability_zone
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "${var.FLEET_PREFIX}_redis"
    Team = var.team
  }
}
