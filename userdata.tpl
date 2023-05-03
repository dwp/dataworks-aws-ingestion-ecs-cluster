#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config

# rename ec2 instance to be unique
export AWS_DEFAULT_REGION=${region}
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
UUID=$(dbus-uuidgen | cut -c 1-8)
export HOSTNAME=${name}-$UUID
hostnamectl set-hostname $HOSTNAME
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$HOSTNAME

echo "Creating directories"
mkdir -p /var/log/ingestion
mkdir -p /opt/ingestion


echo "Downloading startup scripts"
S3_LOGROTATE="s3://${s3_scripts_bucket}/${s3_script_logrotate}"
S3_CLOUDWATCH_SHELL="s3://${s3_scripts_bucket}/${s3_script_cloudwatch_shell}"
S3_LOGGING_SHELL="s3://${s3_scripts_bucket}/${s3_script_logging_shell}"
S3_CONFIG_HCS_SHELL="s3://${s3_scripts_bucket}/${s3_script_config_hcs_shell}"

echo "Copying scripts"
$(which aws) s3 cp "$S3_LOGROTATE"     /etc/logrotate.d/ingestion/ingestion.logrotate
$(which aws) s3 cp "$S3_CLOUDWATCH_SHELL"  /opt/ingestion/cloudwatch.sh
$(which aws) s3 cp "$S3_LOGGING_SHELL"     /opt/ingestion/logging.sh
$(which aws) s3 cp "$S3_CONFIG_HCS_SHELL"  /opt/ingestion/config_hcs.sh

echo "Setup cloudwatch logs"
chmod u+x /opt/ingestion/cloudwatch.sh
/opt/ingestion/cloudwatch.sh \
    "${cwa_metrics_collection_interval}" "${cwa_namespace}" "${cwa_cpu_metrics_collection_interval}" \
    "${cwa_disk_measurement_metrics_collection_interval}" "${cwa_disk_io_metrics_collection_interval}" \
    "${cwa_mem_metrics_collection_interval}" "${cwa_netstat_metrics_collection_interval}" "${cwa_log_group_name}" \
    "$AWS_DEFAULT_REGION"

echo "Setup hcs pre-requisites"
chmod u+x /opt/ingestion/config_hcs.sh
/opt/ingestion/config_hcs.sh "${hcs_environment}" "${proxy_host}" "${proxy_port}"

echo "Creating ingestion user"
useradd ingestion -m

echo "Changing permissions"
chown ingestion:ingestion -R  /opt/ingestion
chown ingestion:ingestion -R  /var/log/ingestion