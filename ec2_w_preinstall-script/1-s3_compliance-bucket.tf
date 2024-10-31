/* 
  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Create EC2 policy to permit EC2 instances access to S3 tools bucket                                              │
  └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 */

resource "aws_iam_policy" "compliance_bucket_permission" {
  name        = "access_s3_bucket_policy"
  description = "A policy that provides full access to a specific S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${module.compliance_bucket.s3_bucket_arn}",
        "${module.compliance_bucket.s3_bucket_arn}/*"
      ]
    }
  ]
}
EOF
}


/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Create S3 Bucket to house compliancy tools & other scripts               │
  └──────────────────────────────────────────────────────────────────────────┘
 */
module "compliance_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "tower-compliance-bucket"

  # Ownership Permissions
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  # Enable object recovery
  versioning = {
    enabled = true
  }

  # Encrypt objects
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Set Bucket Access Policy
  attach_policy = true
  policy        = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "ForceSSLOnlyAccess",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": [
          "${module.compliance_bucket.s3_bucket_arn}/*",
          "${module.compliance_bucket.s3_bucket_arn}"
        ],
        "Condition": {
          "Bool": {
            "aws:SecureTransport": "false"
          }
        }
      },
      {
        "Sid": "PermitServerAccess",
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "${module.ec2-gateways[0].role_arn}",
            "${module.ec2-gateways[1].role_arn}"
          ]
        },
        "Action": "s3:*",
        "Resource": [
          "${module.compliance_bucket.s3_bucket_arn}/*",
          "${module.compliance_bucket.s3_bucket_arn}"
        ],
        "Condition": {
          "StringNotEquals": {
            "s3:x-amz-acl": ["public-read", "public-read-write", "authenticated-read"]
          }
        }
    }
    ]
  }
  POLICY
}


/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Sync scripts and tools with S3 bucket                                    │
  └──────────────────────────────────────────────────────────────────────────┘
 */

resource "aws_s3_object" "windows_scripts" {
  for_each               = fileset("compliance_scripts/windows", "**/*")
  bucket                 = module.compliance_bucket.s3_bucket_id
  key                    = "windows/${each.value}"
  source                 = "compliance_scripts/windows/${each.value}"
  acl                    = "private"
  server_side_encryption = "AES256" # enforce encryption in transport
}

# Upload files in the linux directory
resource "aws_s3_object" "linux_scripts" {
  for_each               = fileset("compliance_scripts/linux", "**/*")
  bucket                 = module.compliance_bucket.s3_bucket_id
  key                    = "linux/${each.value}"
  source                 = "compliance_scripts/linux/${each.value}"
  acl                    = "private"
  server_side_encryption = "AES256" # enforce encryption in transport
}

