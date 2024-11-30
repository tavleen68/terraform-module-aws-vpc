resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count              = var.create_tgw_attachment ? 1 : 0
  subnet_ids         = aws_subnet.private.*.id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id
  tags = merge({
    Name = "${var.orgname}-${var.region_name}-${var.environment}-${var.project_name}-transit-gateway-attachment"
  },
    var.default_tags
  )
}
