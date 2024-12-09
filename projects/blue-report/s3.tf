resource "aws_s3_bucket" "terraform" {
  bucket = "blue-report-terraform"
}

resource "aws_s3_bucket" "site" {
  bucket = "blue-report"
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "WriteOnly",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.blue_report.arn
        },
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.site.arn}/*"
      },
      {
        Sid       = "CloudflareReadOnly",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject",
        ],
        Resource = "${aws_s3_bucket.site.arn}/index.html"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [
              "173.245.48.0/20",
              "103.21.244.0/22",
              "103.22.200.0/22",
              "103.31.4.0/22",
              "141.101.64.0/18",
              "108.162.192.0/18",
              "190.93.240.0/20",
              "188.114.96.0/20",
              "197.234.240.0/22",
              "198.41.128.0/17",
              "162.158.0.0/15",
              "104.16.0.0/13",
              "104.24.0.0/14",
              "172.64.0.0/13",
              "131.0.72.0/22",
              "2400:cb00::/32",
              "2606:4700::/32",
              "2803:f800::/32",
              "2405:b500::/32",
              "2405:8100::/32",
              "2a06:98c0::/29",
              "2c0f:f248::/32",
            ]
          }
        }
      },
      {
        Sid       = "DenyInsecureConnections",
        Effect    = "Deny",
        Principal = "*",
        Action    = ["s3:PutObject", "s3:PutObjectAcl"],
        Resource  = "arn:aws:s3:::blue-report/*",
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::blue-report/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}
