#######################################################################################################
#Create VPC
#######################################################################################################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default" #var.instance_tenancy
  #  assign_generated_ipv6_cidr_block     = var.enable_ipv6 && !var.use_ipam_pool ? true : null
  #  ipv6_cidr_block                      = var.ipv6_cidr

  tags = merge({
    Name = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-vpc-${var.resource_desc}"
    },
    var.default_tags
  )
}
#######################################################################################################
# Public Subnets
#######################################################################################################

resource "aws_subnet" "public" {
  # count = local.create_eks_subnets ? length(var.eks_subnet_cidr_blocks) : 0
  count                   = local.create_public_subnets ? local.len_public_subnets : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnets[count.index].cidr_range
  availability_zone       = var.public_subnets[count.index].az
  map_public_ip_on_launch = var.map_public_ip_on_launch_in_public_subnet
  tags = merge(
    {
      Name = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-${var.public_subnets[count.index].name}-${var.resource_desc}",
    },
    var.default_tags
  )
}

#######################################################################################################
# Private Subnets
#######################################################################################################

resource "aws_subnet" "private" {
  # count = local.create_eks_subnets ? length(var.eks_subnet_cidr_blocks) : 0
  count                   = local.create_private_subnets ? local.len_private_subnets : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnets[count.index].cidr_range
  availability_zone       = var.private_subnets[count.index].az # element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false
  tags = merge(
    {
      Name = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-${var.private_subnets[count.index].name}-${var.resource_desc}",
    },
    var.default_tags
  )
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count  = local.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.vpc.id # local.vpc_id
  tags = merge(
    { "Name" = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-igw-${var.resource_desc}" },
    var.default_tags
  )
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  count = local.create_vpc && var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-nat-eip-${var.resource_desc}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.default_tags
    #.nat_eip_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-nat-gateway-${var.resource_desc}-%s",
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.default_tags
    #.nat_eip_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

################################################################################
# Default route-table route to internet Gateway
################################################################################

resource "aws_route" "internet_route" {
  route_table_id         = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  for_each               = { for idx, gateway_id in aws_internet_gateway.this : idx => gateway_id.id }
  gateway_id             = each.value #value.id
  # gateway_id             = aws_internet_gateway.this[count.index].id
}

################################################################################
# Create private route tables
################################################################################

# Create route tables dynamically
locals {
  route_tables = distinct([for subnet in var.private_subnets : subnet.route_table])
}

resource "aws_route_table" "private" {
  count  = length(local.route_tables)
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { "Name" = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-${local.route_tables[count.index]}"
    },
    var.default_tags
  )
}

# Create subnet associations
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[index(local.route_tables, var.private_subnets[count.index].route_table)].id

}

################################################################################
# Create public route tables
################################################################################

# Create route tables dynamically
locals {
  public_route_tables = distinct([for subnet in var.public_subnets : subnet.route_table])
}

resource "aws_route_table" "public" {
  count  = length(local.public_route_tables)
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { "Name" = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-${local.public_route_tables[count.index]}"
    },
    var.default_tags
  )
}

# Create subnet associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[index(local.public_route_tables, var.public_subnets[count.index].route_table)].id

}

################################################################################
# NAT Route in private route tables
################################################################################

resource "aws_route" "private_nat_gateway" {
  count                  = length(local.route_tables) >0 && var.enable_nat_gateway_route ? length(local.route_tables) : 0
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
  timeouts {
    create = "5m"
  }
}

################################################################################
# IGW Route in public route tables
################################################################################

resource "aws_route" "internet_route-2" {
  count                  = length(local.public_route_tables)
  route_table_id         = element(aws_route_table.public[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

}

################################################################################
################################################################################
