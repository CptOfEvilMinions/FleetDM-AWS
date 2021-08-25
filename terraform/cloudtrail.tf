##############################################################################
# https://github.com/tmknom/terraform-aws-s3-cloudtrail/blob/master/main.tf
##############################################################################
# Generate random S3 suffix
resource "random_string" "s3_suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  bucket_suffix = random_string.s3_suffix.result
  bucket_name = "${replace(join("",[lower(var.FLEET_PREFIX), "_cloudtrail_", local.bucket_suffix]), "_", "-")}"
}

# https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html
resource "aws_s3_bucket_policy" "default" {
  bucket = "${aws_s3_bucket.fleet_cloudtrail_s3_bucket.id}"
  policy = "${data.aws_iam_policy_document.default.json}"
}

# https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
data "aws_iam_policy_document" "default" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "arn:aws:s3:::fleet-cloudtrail-${local.bucket_suffix}",
    ]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::fleet-cloudtrail-${local.bucket_suffix}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

resource "aws_s3_bucket" "fleet_cloudtrail_s3_bucket" {
  bucket        = local.bucket_name
  force_destroy = true
  acl           = "private"

  lifecycle_rule {
    id      = "fleet_60_day_rotation"
    prefix  = "fleet"
    enabled = true

    expiration {
      days = 60
    }
  }
}

resource "aws_cloudtrail" "fleet_cloudtrail" {
  name                          = "fleet_cloudtrail"
  s3_bucket_name                = local.bucket_name
  s3_key_prefix                 = "fleet"
  include_global_service_events = false
}