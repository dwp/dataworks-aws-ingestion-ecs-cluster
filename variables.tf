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
    development = "t3.medium"
    qa          = "t3.medium"
    integration = "t3.large"
    preprod     = "t3.medium"
    production  = "m5.large"
  }
}

variable "ecs_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}

variable "test_ami" {
  description = "Defines if cluster should test untested ECS AMI"
  type        = bool
  default     = false
}

variable "proxy_port" {
  description = "proxy port"
  type        = string
  default     = "3128"
}

variable "tanium_port_1" {
  description = "tanium port 1"
  type        = string
  default     = "16563"
}

variable "tanium_port_2" {
  description = "tanium port 2"
  type        = string
  default     = "16555"
}