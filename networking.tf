resource "aws_route_table" "ingestion_ecs_cluster" {
  vpc_id = data.terraform_remote_state.ingestion.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "application" = local.ingestion_ecs_friendly_name
    },
  )
}

resource "aws_route_table_association" "ingestion_ecs_cluster" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(data.terraform_remote_state.ingestion.outputs.ingestion_subnets.id, count.index)
  route_table_id = aws_route_table.ingestion_ecs_cluster.id
}

resource "aws_route" "ingestion_ecs_cluster_dks" {
  count          = length(data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks, )
  route_table_id = aws_route_table.htme.id
  destination_cidr_block = element(
    local.dks_subnet_cidr,
    count.index,
  )
  vpc_peering_connection_id = data.terraform_remote_state.ingestion.outputs.crypto_main_vpc_peering_acceptor.id
}

resource "aws_route" "dks_ingestion-ecs-cluster" {
  provider                  = aws.management-crypto
  count                     = length(data.terraform_remote_state.ingestion.outputs.ingestion_subnets.cidr_block)
  route_table_id            = data.terraform_remote_state.crypto.outputs.dks_route_table.id
  destination_cidr_block    = element(data.terraform_remote_state.ingestion.outputs.ingestion_subnets.id, count.index)
  vpc_peering_connection_id = data.terraform_remote_state.ingestion.outputs.crypto_main_vpc_peering_acceptor.id
}