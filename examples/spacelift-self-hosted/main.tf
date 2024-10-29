terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "<5.0"
    }

    random = { source = "hashicorp/random" }
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "this" {
  default = true
}

data "aws_security_group" "this" {
  name   = "default"
  vpc_id = data.aws_vpc.this.id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

#### Spacelift (self-hosted) worker pool ####

module "this" {
  source = "../../"

  configuration   = ""
  custom_userdata = templatefile("${path.module}/spacelift-self-hosted-userdata.sh", {
    AWS_REGION                 = "eu-west-1"
    BINARIES_BUCKET            = "183295411930-spacelift-downloads-a75097" # provided by spacelift self-hosted installer
    RunLauncherAsSpaceliftUser = true
    POWER_OFF_ON_ERROR         = true
    SECRET_NAME                = "<Secrets Manager secret containing SPACELIFT_TOKEN and SPACELIFT_POOL_PRIVATE_KEY>"
  })

  security_groups            = [data.aws_security_group.this.id]
  spacelift_api_key_endpoint = var.spacelift_api_key_endpoint
  spacelift_api_key_id       = var.spacelift_api_key_id
  spacelift_api_key_secret   = var.spacelift_api_key_secret
  vpc_subnets                = data.aws_subnets.this.ids
  worker_pool_id             = var.worker_pool_id

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    },
    {
      resource_type = "volume"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    },
    {
      resource_type = "network-interface"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    }
  ]
}
