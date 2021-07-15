resource "aws_ecs_cluster" "ingestion_ecs_cluster" {
  name               = local.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.ingestion_ecs_cluster.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ingestion_ecs_cluster.name
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.ingestion_ecs_friendly_name
    }
  )

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_capacity_provider" "ingestion_ecs_cluster" {
  name = local.ingestion_ecs_friendly_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ingestion_ecs_cluster.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }

  lifecycle {
    ignore_changes = all
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.ingestion_ecs_friendly_name
    }
  )
}

resource "aws_autoscaling_group" "ingestion_ecs_cluster" {
  name_prefix               = "${aws_launch_template.ingestion_ecs_cluster.name}-lt_ver${aws_launch_template.ingestion_ecs_cluster.latest_version}_"
  min_size                  = 0
  desired_capacity          = var.ingestion_ecs_cluster_asg_max[local.environment]
  max_size                  = var.ingestion_ecs_cluster_asg_max[local.environment]
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = data.terraform_remote_state.ingestion.outputs.ingestion_subnets.id


  launch_template {
    id      = aws_launch_template.ingestion_ecs_cluster.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 25
    }
  }

  dynamic "tag" {
    for_each = local.ingestion_ecs_asg_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_template" "ingestion_ecs_cluster" {
  name          = local.ingestion_ecs_friendly_name
  image_id      = var.ecs_hardened_ami_id
  instance_type = var.ingestion_ecs_cluster_ec2_size[local.environment]

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      aws_security_group.ingestion_ecs_cluster.id
    ]
  }

  user_data = base64encode(templatefile("userdata.tpl", {
    cluster_name = local.cluster_name # Referencing the cluster resource causes a circular dependency
    region       = data.aws_region.current.name
    name         = local.ingestion_ecs_friendly_name

  }))

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.ingestion_ecs_cluster.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = local.ingestion_ecs_cluster_ebs_volume_size[local.environment]
      volume_type           = local.ingestion_ecs_cluster_ebs_volume_type[local.environment]
      delete_on_termination = true
      encrypted             = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.ingestion_ecs_friendly_name
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name                = local.ingestion_ecs_friendly_name,
        AutoShutdown        = local.ingestion_ecs_cluster_asg_autoshutdown[local.environment],
        SSMEnabled          = local.ingestion_ecs_cluster_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = local.ingestion_ecs_friendly_name,
      }
    )
  }
}

resource "aws_cloudwatch_log_group" "ingestion_ecs_cluster" {
  name              = local.cw_agent_log_group_name_ingestion_ecs
  retention_in_days = 180
  tags              = local.common_tags
}

resource "aws_iam_instance_profile" "ingestion_ecs_cluster" {
  name = local.ingestion_ecs_friendly_name
  role = aws_iam_role.ingestion_ecs_cluster.name
}

data "aws_iam_policy_document" "ingestion_ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingestion_ecs_cluster" {
  name                 = local.ingestion_ecs_friendly_name
  assume_role_policy   = data.aws_iam_policy_document.ingestion_ecs_assume_role.json
  max_session_duration = local.iam_role_max_session_timeout_seconds
  tags                 = local.common_tags
}

data "aws_iam_policy_document" "ingestion_ecs_cluster" {

  statement {
    sid    = "AllowUseDefaultEbsCmk"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = [data.terraform_remote_state.security-tools.outputs.ebs_cmk.arn]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToConfigBucket"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [data.terraform_remote_state.common.outputs.config_bucket.arn]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToConfigBucketObjects"

    actions = ["s3:GetObject"]

    resources = ["${data.terraform_remote_state.common.outputs.config_bucket.arn}/*"]
  }

  statement {
    sid    = "AllowKMSDecryptionOfS3ConfigBucketObj"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [data.terraform_remote_state.common.outputs.config_bucket_cmk.arn]
  }

  statement {
    sid     = "AllowAccessToArtefactBucket"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation"]

    resources = [data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn]
  }

  statement {
    sid       = "AllowPullFromArtefactBucket"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${data.terraform_remote_state.management_artefact.outputs.artefact_bucket.arn}/*"]
  }

  statement {
    sid    = "AllowDecryptArtefactBucket"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [data.terraform_remote_state.management_artefact.outputs.artefact_bucket.cmk_arn]
  }

  statement {
    sid    = "AllowAccessLogGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.ingestion_ecs_cluster.arn,
      data.terraform_remote_state.common.outputs.ami_ecs_test_log_group_arn
    ]
  }

  statement {
    sid    = "EnableEC2TaggingHost"
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:*Tags",
    ]
    resources = ["arn:aws:ec2:${var.region}:${local.account[local.environment]}:instance/*"]
  }
}

resource "aws_iam_policy" "ingestion_ecs_cluster" {
  name        = local.ingestion_ecs_friendly_name
  description = "Ingestion ECS cluster Policy"
  policy      = data.aws_iam_policy_document.ingestion_ecs_cluster.json
}

resource "aws_iam_role_policy_attachment" "ingestion_ecs_cluster" {
  role       = aws_iam_role.ingestion_ecs_cluster.name
  policy_arn = aws_iam_policy.ingestion_ecs_cluster.arn
}

resource "aws_iam_role_policy_attachment" "ingestion_ecs_cwasp" {
  role       = aws_iam_role.ingestion_ecs_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ingestion_ecs_ssm" {
  role       = aws_iam_role.ingestion_ecs_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ingestion_ecs" {
  role       = aws_iam_role.ingestion_ecs_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
