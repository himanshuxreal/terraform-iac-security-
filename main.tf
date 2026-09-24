terraform { 
  required_providers { 
    aws = { 
      source  = "hashicorp/aws" 
    } 
  } 
} 
 
provider "aws" { 
  region = "ap-south-1" 
} 
 
# ---------------------------------------------------------
# Primary Bucket Configuration
# ---------------------------------------------------------
resource "aws_s3_bucket" "lab_bucket" { 
  bucket = "terraform-iac-security" 
} 

# 1. Block Public Access (Secure by Default)
resource "aws_s3_bucket_public_access_block" "lab_bucket_pab" {
  bucket                  = aws_s3_bucket.lab_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Enable Server-Side Encryption (Secure by Default)
resource "aws_s3_bucket_server_side_encryption_configuration" "lab_bucket_sse" {
  bucket = aws_s3_bucket.lab_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Enforce HTTPS-Only Access (SonarQube Remediation)
resource "aws_s3_bucket_policy" "lab_bucket_policy" {
  bucket = aws_s3_bucket.lab_bucket.id
  policy = data.aws_iam_policy_document.require_https.json
}

data "aws_iam_policy_document" "require_https" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.lab_bucket.arn,
      "${aws_s3_bucket.lab_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# 4. Enable Access Logging (SonarQube Remediation)
resource "aws_s3_bucket_logging" "lab_bucket_logging" {
  bucket = aws_s3_bucket.lab_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# ---------------------------------------------------------
# Logging Bucket Configuration
# ---------------------------------------------------------
resource "aws_s3_bucket" "log_bucket" {
  bucket = "terraform-iac-security-logs"
}

# Ensure the log bucket is also secure by default
resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_sse" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.log_bucket_require_https.json
}

data "aws_iam_policy_document" "log_bucket_require_https" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.log_bucket.arn,
      "${aws_s3_bucket.log_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Configure Ownership Controls & ACL to allow AWS S3 log delivery
resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership]
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}