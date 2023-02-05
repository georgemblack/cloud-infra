terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket = "terraform.george.black"
    prefix = "mastodon"
  }
}

provider "aws" {
  region = "us-east-2"
}
