locals {
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

  ingestion_ecs_cluster_ebs_volume_size = {
    development = 667
    qa          = 667
    integration = 667
    preprod     = 667
    production  = 667
  }

  ingestion_ecs_cluster_ebs_volume_type = {
    development = "gp3"
    qa          = "gp3"
    integration = "gp3"
    preprod     = "gp3"
    production  = "gp3"
  }
}
