locals {
  security_group_rules = [
    {
      name : "Ingest ECS Cluster VPC endpoints"
      port : 443
      destination : data.terraform_remote_state.ingestion.outputs.vpc.vpc.interface_vpce_sg_id
    },
    {
      name : "Ingest ECS Cluster internet proxy endpoints (for ACM-PCA)"
      port : 3128
      destination : data.terraform_remote_state.ingestion.outputs.internet_proxy.sg
    },
  ]
}

resource "aws_security_group" "ingestion_ecs_cluster" {
  name                   = local.ingestion_ecs_friendly_name
  description            = "Ingestion ECS cluster"
  revoke_rules_on_delete = true
  vpc_id                 = data.terraform_remote_state.ingestion.outputs.vpc.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = local.ingestion_ecs_friendly_name
    }
  )
}

resource "aws_security_group_rule" "ingress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.ingestion_ecs_cluster.id
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = each.value.destination
  security_group_id        = aws_security_group.ingestion_ecs_cluster.id
}

resource "aws_security_group_rule" "ingestion_ecs_to_s3" {
  description       = "Access to S3 https"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.ingestion.outputs.vpc.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.ingestion_ecs_cluster.id
}

resource "aws_security_group_rule" "ingestion_ecs_to_s3_http" {
  description       = "Access to S3 http"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.ingestion.outputs.vpc.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.ingestion_ecs_cluster.id
}
