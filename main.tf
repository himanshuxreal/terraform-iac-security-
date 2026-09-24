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
 
resource "aws_s3_bucket" "lab_bucket" { 
  bucket = "terraform-iac-security" 
} 