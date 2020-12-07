locals {
  security_group_rules = [
    {
      name : "Ingest ECS Cluster VPC endpoints"
      port : 443
      count : 1
      protocol : "tcp"
      destination : data.terraform_remote_state.ingestion.outputs.vpc.vpc.interface_vpce_sg_id
    },
    {
      name : "Ingest ECS Cluster internet proxy endpoints (for ACM-PCA)"
      port : 3128
      count : 1
      protocol : "tcp"
      destination : data.terraform_remote_state.ingestion.outputs.internet_proxy.sg
    },
    {
      name : "STUB Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      count : local.kafka_data_source_is_ucfs[local.environment] ? 0 : 1
      protocol : "tcp"
      destination : local.stub_ucfs_subnets.cidr_block
    },
    {
      name : "UCFS Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      count : local.kafka_data_source_is_ucfs[local.environment] ? 1 : 0
      protocol : "tcp"
      destination : local.ucfs_broker_cidr_blocks[local.environment]
    },
    {
      name : "London UCFS Kafka brokers"
      port : local.kafka_broker_port[local.environment]
      count : (local.k2hb_data_source_is_ucfs[local.environment] || local.peer_with_ucfs_london[local.environment]) ? 1 : 0
      protocol : "tcp"
      destination : local.ucfs_london_broker_cidr_blocks[local.environment]
    },
    {
      name : "UCFS DNS Name servers in Ireland"
      port : 53
      count : local.peer_with_ucfs[local.environment] ? 1 : 0
      protocol : "all"
      destination : local.ucfs_nameservers_cidr_blocks[local.environment]
    },
    {
      name : "UCFS DNS Name servers in London"
      port : 53
      count : local.peer_with_ucfs[local.environment] ? 1 : 0
      protocol : "all"
      destination : local.ucfs_london_nameservers_cidr_blocks[local.environment]
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
  count                    = each.value.count
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.ingestion_ecs_cluster.id
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for security_group_rule in local.security_group_rules : security_group_rule.port => security_group_rule }
  count                    = each.value.count
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
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
