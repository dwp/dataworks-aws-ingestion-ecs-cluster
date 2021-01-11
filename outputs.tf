output "ingestion_ecs_cluster" {
  value = aws_ecs_cluster.ingestion_ecs_cluster
}

output "ingestion_ecs_cluster_autoscaling_group" {
  value = aws_autoscaling_group.ingestion_ecs_cluster
}

output "ingestion_ecs_cluster_security_group" {
  value = aws_security_group.ingestion_ecs_cluster
}
