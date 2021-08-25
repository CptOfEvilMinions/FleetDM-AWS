provider "aws" {
  region = "us-east-2"
}

terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "fleet-terraform-784rhj"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "fleet-terraform-784rhj"
    encrypt        = true
  }
}