output "ingestion_ecs_cluster" {
  value = {
    id   = aws_ecs_cluster.ingestion_ecs_cluster.id
    arn  = aws_ecs_cluster.ingestion_ecs_cluster.arn
    name = aws_ecs_cluster.ingestion_ecs_cluster.name
  }
}

output "ingestion_ecs_cluster_autoscaling_group" {
  value = {
    id   = aws_autoscaling_group.ingestion_ecs_cluster.id
    arn  = aws_autoscaling_group.ingestion_ecs_cluster.arn
    name = aws_autoscaling_group.ingestion_ecs_cluster.name
    max_size = aws_autoscaling_group.ingestion_ecs_cluster.max_size
    name_prefix = aws_autoscaling_group.ingestion_ecs_cluster.name_prefix
  }
}

output "ingestion_ecs_cluster_security_group" {
  value = {
    id   = aws_security_group.ingestion_ecs_cluster.id
    arn  = aws_security_group.ingestion_ecs_cluster.arn
    name = aws_security_group.ingestion_ecs_cluster.name
  }
}
