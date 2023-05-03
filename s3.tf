
data "local_file" "ingestion_logrotate_script" {
  filename = "files/ingestion.logrotate"
}

resource "aws_s3_object" "ingestion_logrotate_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/ingestion/ingestion.logrotate"
  content    = data.local_file.ingestion_logrotate_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn



  tags = merge(
    local.common_tags,
    {
      Name = "ingestion-logrotate-script"
    },
  )
}

data "local_file" "ingestion_cloudwatch_script" {
  filename = "files/ingestion_cloudwatch.sh"
}

resource "aws_s3_object" "ingestion_cloudwatch_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/ingestion/ingestion-cloudwatch.sh"
  content    = data.local_file.ingestion_cloudwatch_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "ingestion-cloudwatch-script"
    },
  )
}

data "local_file" "ingestion_logging_script" {
  filename = "files/logging.sh"
}

resource "aws_s3_object" "ingestion_logging_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/ingestion/ingestion-logging.sh"
  content    = data.local_file.ingestion_logging_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "ingestion-logging-script"
    },
  )
}

data "local_file" "ingestion_config_hcs_script" {
  filename = "files/config_hcs.sh"
}

resource "aws_s3_object" "ingestion_config_hcs_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/ingestion/ingestion-config-hcs.sh"
  content    = data.local_file.ingestion_config_hcs_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "ingestion-config-hcs-script"
    },
  )
}
