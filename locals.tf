locals {
  len_public_subnets  = length(var.public_subnets)
  len_private_subnets = length(var.private_subnets)
  #  len_web_subnets      = length(var.web_subnets)
  #  len_eks_subnets      = length(var.eks_subnets)
  #  len_database_subnets = length(var.database_subnets)

  max_subnet_length = max(
    #    local.len_web_subnets,
    #    local.len_eks_subnets,
    #    local.len_database_subnets,
    local.len_private_subnets,
    local.len_public_subnets
  )

  #  Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  #  vpc_id = try(aws_vpc_ipv4_cidr_block_association.this[0].vpc_id, aws_vpc.this[0].id, "")

  create_vpc = var.create_vpc
}

data "aws_availability_zones" "available" {}

locals {
  name     = var.name
  region   = var.region
  vpc_cidr = var.vpc_cidr_block
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

locals {
  create_private_subnets     = local.create_vpc && local.len_private_subnets > 0
  create_private_route_table = local.create_private_subnets && var.create_private_subnet_route_table
}
locals {
  create_public_subnets = local.create_vpc && local.len_public_subnets > 0
}

#locals {
#  create_eks_subnets = local.create_vpc && local.len_eks_subnets > 0
#}

#locals {
#  create_database_subnets     = local.create_vpc && local.len_database_subnets > 0
#  create_database_route_table = local.create_database_subnets && var.create_database_subnet_route_table
#}

#locals {
#  create_web_subnets = local.create_vpc && local.len_web_subnets > 0
#  #create_database_route_table = local.create_database_subnets && var.create_database_subnet_route_table
#}

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length
  nat_gateway_ips   = var.reuse_nat_ips ? var.external_nat_ip_ids : try(aws_eip.nat[*].id, [])
}