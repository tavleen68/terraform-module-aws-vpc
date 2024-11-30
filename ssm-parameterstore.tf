################################################################################
# Locals
################################################################################

locals {
  ssm_id                 = "/${var.orgname}/${var.region_name}/${var.environment}/${var.project_name}/vpc"
  public_subnet_ids      = length(aws_subnet.public) > 0 ? join(",", aws_subnet.public[*].id) : null
  private_subnet_ids     = length(aws_subnet.private) > 0 ? join(",", aws_subnet.private[*].id) : null
  aws_nat_gateway_id     = length(aws_nat_gateway.this) > 0 ? join(",", aws_nat_gateway.this[*].id) : null
  internet_gateway_id    = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
  private_route_table_id = length(aws_route_table.private) > 0 ? join(",", aws_route_table.private[*].id) : null
  public_route_table_id  = length(aws_nat_gateway.this) > 0 ? join(",", aws_route_table.public[*].id) : null

  # Convert values to maps for conditional creation
  public_subnet_ids_map      = local.public_subnet_ids != null ? { "exists" = local.public_subnet_ids } : {}
  private_subnet_ids_map     = local.private_subnet_ids != null ? { "exists" = local.private_subnet_ids } : {}
  aws_nat_gateway_id_map     = local.aws_nat_gateway_id != null ? { "exists" = local.aws_nat_gateway_id } : {}
  internet_gateway_id_map    = local.internet_gateway_id != null ? { "exists" = local.internet_gateway_id } : {}
  private_route_table_id_map = local.private_route_table_id != null ? { "exists" = local.private_route_table_id } : {}
  public_route_table_id_map  = local.public_route_table_id != null ? { "exists" = local.public_route_table_id } : {}
}

################################################################################
# SSM Parameter Stores
################################################################################

resource "aws_ssm_parameter" "vpc_id" {
  name  = "${local.ssm_id}/vpc_id"
  type  = "String"
  value = aws_vpc.vpc.id
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  for_each = local.public_subnet_ids_map
  name     = "${local.ssm_id}/public_subnet_ids"
  type     = "StringList"
  value    = each.value
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  for_each = local.private_subnet_ids_map
  name     = "${local.ssm_id}/private_subnet_ids"
  type     = "StringList"
  value    = each.value
}

resource "aws_ssm_parameter" "aws_nat_gateway_id" {
  for_each = local.aws_nat_gateway_id_map
  name     = "${local.ssm_id}/aws_nat_gateway_id"
  type     = "StringList"
  value    = each.value
}

resource "aws_ssm_parameter" "internet_gateway_id" {
  for_each = local.internet_gateway_id_map
  name     = "${local.ssm_id}/internet_gateway_id"
  type     = "String"
  value    = each.value
}

resource "aws_ssm_parameter" "private_route_table_id" {
  for_each = local.private_route_table_id_map
  name     = "${local.ssm_id}/private_route_table_id"
  type     = "String"
  value    = each.value
}

resource "aws_ssm_parameter" "public_route_table_id" {
  for_each = local.public_route_table_id_map
  name     = "${local.ssm_id}/public_route_table_id"
  type     = "String"
  value    = each.value
}
