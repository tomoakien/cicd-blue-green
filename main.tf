#terraform初期設定
terraform {
  required_version = ">=1.9.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

#provider設定
provider "aws" {
  region = "ap-northeast-1"
}
