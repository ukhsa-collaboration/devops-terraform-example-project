locals {
  private_subnet_cidrs = [
    for i in range(3) : cidrsubnet(var.vpc_cidr_block, 4, i)
  ]
  public_subnet_cidrs = [
    for i in range(3) : cidrsubnet(var.vpc_cidr_block, 4, i+10)
  ]
  availability_zones = [for az in data.aws_availability_zones.available.names : az]
}