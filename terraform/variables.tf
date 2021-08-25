variable "public_domain" {
  type = string
  default = "aws.hackinglab.beer"
}

variable "internal_domain" {
  type = string
  default = "fleet.local"
}

variable "FLEET_PREFIX" {
  type    = string
  default = "FLEET"
}

variable "team" {
  type = string
  default = "security"
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "vpc_subnets" {
  type = map
  default = {
    "private-a" = "172.16.34.0/24"
    "private-b" = "172.16.35.0/24"
    "public" = "172.16.43.0/24"
  }
}


variable "region" {
  type    = string
  default = "us-east-2"
}

variable "availability_zone" {
  type    = string
  default = "us-east-2b"
}


variable "fleet_version" {
  type    = string
  default = "4.2.2"
}

