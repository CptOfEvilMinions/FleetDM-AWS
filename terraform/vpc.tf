############################################# Create VPC ############################################
resource "aws_vpc" "fleet_vpc" {                
  cidr_block            = var.vpc_cidr
  instance_tenancy      = "default"
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC"
    Team = var.team
  }
}

############################################ Create the Internet Gateway ############################################
resource "aws_internet_gateway" "VPC_IGW" {
	vpc_id = aws_vpc.fleet_vpc.id
	tags = {
		Name = "${var.FLEET_PREFIX}_VPC_Internet_Gateway"
    Team = var.team
	}
}

############################################ Create VPC public subnet ############################################
resource "aws_subnet" "fleet_public_A_subnet" {
  vpc_id                  = aws_vpc.fleet_vpc.id
  cidr_block              = var.vpc_subnets["public-a"]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_public_A_subnet"
    Team = var.team
  }
}

resource "aws_subnet" "fleet_public_B_subnet" {
  vpc_id                  = aws_vpc.fleet_vpc.id
  cidr_block              = var.vpc_subnets["public-b"]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_public_B_subnet"
    Team = var.team
  }
}


# Create the Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.fleet_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.VPC_IGW.id
  }

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_public_route_table"
    Team = var.team
 	}
}

# Associate the management Route Table with the management Subnet
resource "aws_route_table_association" "fleet_public_A_subnet_route_table_association" {
  subnet_id      = aws_subnet.fleet_public_A_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "fleet_public_B_subnet_route_table_association" {
  subnet_id      = aws_subnet.fleet_public_B_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


############################################ Create VPC private subnets ############################################
resource "aws_subnet" "fleet_private_a_subnet" {
  vpc_id            = aws_vpc.fleet_vpc.id
  cidr_block        = var.vpc_subnets["private-a"]
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_private_a_subnet"
    Team = var.team
  }
}

resource "aws_subnet" "fleet_private_b_subnet" {
  vpc_id            = aws_vpc.fleet_vpc.id
  cidr_block        = var.vpc_subnets["private-b"]
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_private_b_subnet"
    Team = var.team
  }
}

resource "aws_eip" "nat_gw_a_eip" {
    vpc = true
    tags = {
      Name = "${var.FLEET_PREFIX}_NAT_A_gateway_eip"
      Team = var.team
    }
}


resource "aws_eip" "nat_gw_b_eip" {
    vpc = true
    tags = {
      Name = "${var.FLEET_PREFIX}_NAT_B_gateway_eip"
      Team = var.team
    }
}

resource "aws_nat_gateway" "nat_A_gw" {
    allocation_id = aws_eip.nat_gw_a_eip.id
    subnet_id     = aws_subnet.fleet_public_A_subnet.id
    tags = {
      Name = "${var.FLEET_PREFIX}_NAT_A_gateway"
      Team = var.team
    }

}

resource "aws_nat_gateway" "nat_B_gw" {
    allocation_id = aws_eip.nat_gw_b_eip.id
    subnet_id     = aws_subnet.fleet_public_B_subnet.id
    tags = {
      Name = "${var.FLEET_PREFIX}_NAT_B_gateway"
      Team = var.team
    }

}

resource "aws_route_table" "fleet_private_a_route_table" {
  vpc_id = aws_vpc.fleet_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_A_gw.id
  }

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_private_A_route_table"
    Team = var.team
 	}
}

resource "aws_route_table" "fleet_private_b_route_table" {
  vpc_id = aws_vpc.fleet_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_B_gw.id
  }

  tags = {
    Name = "${var.FLEET_PREFIX}_VPC_private_B_route_table"
    Team = var.team
 	}
}


# Associate the management Route Table with the management Subnet
resource "aws_route_table_association" "fleet_private_a_subnet_route_table_association" {
  subnet_id      = aws_subnet.fleet_private_a_subnet.id
  route_table_id = aws_route_table.fleet_private_a_route_table.id
}

resource "aws_route_table_association" "fleet_private_b_subnet_route_table_association" {
  subnet_id      = aws_subnet.fleet_private_b_subnet.id
  route_table_id = aws_route_table.fleet_private_b_route_table.id
}