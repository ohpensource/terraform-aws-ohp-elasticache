resource "aws_elasticache_replication_group" "default" {
  count = var.enable_module ? 1 : 0

  auth_token                    = var.transit_encryption_enabled ? var.auth_token : null
  replication_group_id          = var.replication_group_id == "" ? "${var.name}-replicationgroup" : var.replication_group_id
  replication_group_description = "${var.name}-replicationgroup"
  node_type                     = var.instance_type
  number_cache_clusters         = var.cluster_mode_enabled ? null : var.cluster_size
  port                          = var.port
  parameter_group_name          = join("", aws_elasticache_parameter_group.default.*.name)
  availability_zones            = var.availability_zones
  multi_az_enabled              = var.multi_az_enabled
  subnet_group_name             = local.elasticache_subnet_group_name
  security_group_ids            = var.security_groups
  maintenance_window            = var.maintenance_window
  engine_version                = var.engine_version
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = var.auth_token != null ? coalesce(true, var.transit_encryption_enabled) : var.transit_encryption_enabled
  kms_key_id                    = var.kms_key_id
  snapshot_name                 = var.snapshot_name
  snapshot_arns                 = var.snapshot_arns
  snapshot_window               = var.snapshot_window
  snapshot_retention_limit      = var.snapshot_retention_limit
  final_snapshot_identifier     = var.final_snapshot_identifier
  apply_immediately             = var.apply_immediately

  tags = var.tags

  dynamic "cluster_mode" {
    for_each = var.cluster_mode_enabled ? ["true"] : []
    content {
      replicas_per_node_group = var.cluster_mode_replicas_per_node_group
      num_node_groups         = var.cluster_mode_num_node_groups
    }
  }

}

resource "aws_elasticache_parameter_group" "default" {
  count  = var.enable_module ? 1 : 0
  name   = "${var.name}-paramgroup"
  family = var.family

  dynamic "parameter" {
    for_each = var.cluster_mode_enabled ? concat([{ name = "cluster-enabled", value = "yes" }], var.parameter) : var.parameter
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

resource "aws_elasticache_subnet_group" "default" {
  count      = var.enable_module && var.elasticache_subnet_group_name == "" && length(var.subnets) > 0 ? 1 : 0
  name       = "${var.name}-subnetgroup"
  subnet_ids = var.subnets
}

