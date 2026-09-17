terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }

  # terraform-aws-modules/eks v21 requires >= 1.5.7
  required_version = ">= 1.5.7"

  backend "s3" {
    ### Bucket and Key are set during github action pipeline flag = -backend-config="bucket=${{ github.event.inputs.NAME_PREFIX }}-s3-tfstate" -backend-config="key=${{ github.event.inputs.NAME_PREFIX }}-infra.tfstate"
    #    bucket = data.aws_s3_bucket.s3-tfstate.bucket
    #    key    = "${local.cluster_name}.tfstate"
    #    region = var.region
  }
}

