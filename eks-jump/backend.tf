terraform {
  required_version = "~> 1.12.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }

  backend "s3" {
    bucket         = "use1-remote-terraform-state-file-jump-bucket-murali"
    key            = "eks-jump/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-jump-locks"
  }
}
