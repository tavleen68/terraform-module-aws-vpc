#orgname = ot
#environment =poc
#region = eucen1
#projectname = cicm
#resourcename = vpc
#description = common
#EX - ot-poc-cicm-eucen1-vpc-common = ${var.orgname}-${var.environment}-${var.projectname}-${var.region_name}-${resourcename}-${resource_desc}

#locals {
#  id = "${var.orgname}-${var.environment}-${var.project_name}-${var.region_name}-${var.resourcename}-${resource_desc}"
#}

terraform {
  required_version = ">= 0.12" // Specify the minimum required version
}

variable "orgname" {
  description = "the orgname to be used for naming convention"
  type        = string
  default     = null
}

variable "project_name" {
  description = "the project name to be used for naming convention"
  type        = string
  default     = null
}

variable "region_name" {
  description = "the region name to be used for naming convention"
  type        = string
  default     = null
}

variable "resource_desc" {
  description = "the resource desc to be used for naming convention"
  type        = string
  default     = null
}

variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = null
}

variable "region" {
  type        = string
  description = "the region in which VPC need to be created"
  default     = null
}
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = null
}
variable "environment" {
  type        = string
  description = "namespace to segregate the resources from other environment and used in the naming convention"
  default     = null
}

variable "default_tags" {
  description = "Additional resource tags to be applied to all the resources created"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = null
}

###############################################################################
# Publiс Subnets
################################################################################

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type = list(object({
    name        = string
    cidr_range  = string
    route_table = string
    az          = string
  }))
  default = []
}

################################################################################
# Private Subnets
################################################################################

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type = list(object({
    name        = string
    cidr_range  = string
    route_table = string
    az          = string
    #nat_gw      = string
  }))
  default = []
}

variable "create_private_subnet_route_table" {
  description = "Controls if separate route table for database should be created"
  type        = bool
  default     = true
}

variable "create_private_internet_gateway_route" {
  description = "Controls if an internet gateway route for public database access should be created"
  type        = bool
  default     = false
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
}

variable "eks_subnets" {
  description = "list of eks subnets cidr range"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "list of database subnets cidr range"
  type        = list(string)
  default     = []
}
variable "web_subnets" {
  description = "list of web subnets cidr range"
  type        = list(string)
  default     = []
}

##NAT GATEWAY
variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`"
  type        = bool
  default     = null
}
variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = null
}
variable "reuse_nat_ips" {
  description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable"
  type        = bool
  default     = null
}
variable "external_nat_ip_ids" {
  description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
  type        = list(string)
  default     = []
}
variable "nat_gateway_destination_cidr_block" {
  description = "Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route"
  type        = string
  default     = "0.0.0.0/0"
}

variable "map_public_ip_on_launch_in_public_subnet" {
  type        = bool
  description = "Assign public ip on lunch to resources in public subnet"
  default     = false
}

variable "enable_nat_gateway_route" {
  description = "enable nat gateway route to private route table to provide internet connection"
  default     = false
  type        = bool
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
}

variable "create_tgw_attachment" {
  description = "create transit gateway attachment"
  default = "false"
}

variable "transit_gateway_id" {
  description = "Transit gateway ID"
  default = ""
}