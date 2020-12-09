variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "ingestion_ecs_cluster_asg_max" {
  description = "Max ingestion asg size"
  default = {
    development = 9
    qa          = 9
    integration = 9
    preprod     = 9
    production  = 9
  }
}

variable "ingestion_ecs_cluster_ec2_size" {
  default = {
    development = "t3.large"
    qa          = "t3.large"
    integration = "t3.large"
    preprod     = "t3.large"
    production  = "m5.large"
  }
}

variable "ecs_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}
