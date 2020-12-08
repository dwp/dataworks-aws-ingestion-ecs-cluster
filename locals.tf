locals {
  management_account = {
    development = "management-dev"
    qa          = "management-dev"
    integration = "management-dev"
    preprod     = "management"
    production  = "management"
  }

  dks_subnet_cidr = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks

  stub_ucfs_subnets            = data.terraform_remote_state.ingestion.outputs.stub_ucfs_subnets
  stub_kafka_broker_port_https = data.terraform_remote_state.ingestion.outputs.locals.stub_kafka_broker_port_https

  ucfs_broker_cidr_blocks             = data.terraform_remote_state.ingestion.outputs.locals.ucfs_broker_cidr_blocks
  ucfs_london_broker_cidr_blocks      = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_broker_cidr_blocks
  ucfs_nameservers_cidr_blocks        = data.terraform_remote_state.ingestion.outputs.locals.ucfs_nameservers_cidr_blocks
  ucfs_london_nameservers_cidr_blocks = data.terraform_remote_state.ingestion.outputs.locals.ucfs_london_nameservers_cidr_blocks

  kafka_data_source_is_ucfs = data.terraform_remote_state.ingestion.outputs.locals.k2hb_data_source_is_ucfs
  peer_with_ucfs            = data.terraform_remote_state.ingestion.outputs.locals.peer_with_ucfs
  peer_with_ucfs_london     = data.terraform_remote_state.ingestion.outputs.locals.peer_with_ucfs_london

  ingestion_ecs_friendly_name = "ingestion-ecs-cluster"
  cluster_name                = replace(local.ingestion_ecs_friendly_name, "-ecs-cluster", "")

  iam_role_max_session_timeout_seconds = 43200

  cw_agent_namespace_ingestion_ecs      = "/app/${local.ingestion_ecs_friendly_name}"
  cw_agent_log_group_name_ingestion_ecs = "/app/${local.ingestion_ecs_friendly_name}"

  ingestion_ecs_cluster_asg_autoshutdown = {
    development = "False"
    qa          = "False"
    integration = "False"
    preprod     = "False"
    production  = "False"
  }

  ingestion_ecs_cluster_asg_ssmenabled = {
    development = "True"
    qa          = "True"
    integration = "True"
    preprod     = "False"
    production  = "False"
  }

  ingestion_ecs_asg_tags = merge(
    local.common_tags,
    {
      Name         = local.ingestion_ecs_friendly_name,
      AutoShutdown = local.ingestion_ecs_cluster_asg_autoshutdown[local.environment],
      SSMEnabled   = local.ingestion_ecs_cluster_asg_ssmenabled[local.environment],
      Persistence  = "Ignore",
    }
  )

  kafka_broker_port = {
    development = local.stub_kafka_broker_port_https
    qa          = local.stub_kafka_broker_port_https
    integration = local.k2hb_data_source_is_ucfs[local.environment] ? local.uc_kafka_broker_port_https : local.stub_kafka_broker_port_https
    preprod     = local.uc_kafka_broker_port_https
    production  = local.uc_kafka_broker_port_https
  }
}
