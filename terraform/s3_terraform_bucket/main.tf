provider "aws" {
  region = "us-east-2"
}

variable "s3_bucket_suffix" {
  type = string
  default = "784rhj"
}

# https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa
resource "aws_s3_bucket" "terraform_state" {
  bucket = "fleet-terraform-${var.s3_bucket_suffix}"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "fleet-terraform-${var.s3_bucket_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}