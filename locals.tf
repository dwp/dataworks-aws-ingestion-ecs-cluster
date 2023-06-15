locals {
  ingestion_ecs_friendly_name = "ingestion-ecs-cluster"
  cluster_name                = replace(local.ingestion_ecs_friendly_name, "-ecs-cluster", "")

  iam_role_max_session_timeout_seconds = 43200

  cw_agent_namespace_ingestion_ecs                      = "/app/${local.ingestion_ecs_friendly_name}"
  cw_agent_log_group_name_ingestion_ecs                 = "/app/${local.ingestion_ecs_friendly_name}"
  cw_agent_metrics_collection_interval                  = 60
  cw_agent_cpu_metrics_collection_interval              = 60
  cw_agent_disk_measurement_metrics_collection_interval = 60
  cw_agent_disk_io_metrics_collection_interval          = 60
  cw_agent_mem_metrics_collection_interval              = 60
  cw_agent_netstat_metrics_collection_interval          = 60

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

  tenable_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  trend_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  tanium_install = {
    development    = "false"
    qa             = "false"
    integration    = "false"
    preprod        = "false"
    production     = "false"
    management-dev = "false"
    management     = "false"
  }


  ## Tanium config
  ## Tanium Servers
  tanium1 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_1
  tanium2 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_2

  ## Tanium Env Config
  tanium_env = {
    development    = "pre-prod"
    qa             = "prod"
    integration    = "prod"
    preprod        = "prod"
    production     = "prod"
    management-dev = "pre-prod"
    management     = "prod"
  }

  ## Tanium prefix list for TGW for Security Group rules
  tanium_prefix = {
    development    = [data.aws_ec2_managed_prefix_list.list.id]
    qa             = [data.aws_ec2_managed_prefix_list.list.id]
    integration    = [data.aws_ec2_managed_prefix_list.list.id]
    preprod        = [data.aws_ec2_managed_prefix_list.list.id]
    production     = [data.aws_ec2_managed_prefix_list.list.id]
    management-dev = [data.aws_ec2_managed_prefix_list.list.id]
    management     = [data.aws_ec2_managed_prefix_list.list.id]
  }

  tanium_log_level = {
    development    = "41"
    qa             = "41"
    integration    = "41"
    preprod        = "41"
    production     = "41"
    management-dev = "41"
    management     = "41"
  }

  ## Trend config
  tenant   = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenant
  tenantid = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenantid
  token    = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.token

  policy_id = {
    development    = "69"
    qa             = "69"
    integration    = "69"
    preprod        = "69"
    production     = "69"
    management-dev = "69"
    management     = "69"
  }
}
