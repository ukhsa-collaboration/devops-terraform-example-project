module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  create_cluster  = true
  create_replication_group = false
  cluster_id      = "memcached-cluster"
  engine          = "memcached"
  node_type       = "cache.t2.micro"
  num_cache_nodes = 1

  create_parameter_group = true
  parameter_group_name = "memcached-cluster-pg"
  parameter_group_family = "memcached1.6"
  transit_encryption_enabled = false
  parameters = [
    {
      name  = "idle_timeout"
      value = 60
    }
  ]

  vpc_id = data.aws_vpc.main.id
  security_group_rules = {
    ingress_vpc = {
      description = "VPC traffic"
      cidr_ipv4   = data.aws_vpc.main.cidr_block_associations[0].cidr_block
    }
  }

  subnet_ids = data.aws_subnets.public.ids
}