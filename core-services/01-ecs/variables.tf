variable "compute_ami_id" {
    description = "The AMI ID to use on the compute EC2 instance"
    type = string
    default = "ami-05d6c5e5d6fc4f650"
}

variable "compute_instance_type" {
    description = "The EC2 type to use for the ECS compute instances"
    type = string
    default = "t2.micro"
}

variable "ecs_cluster_name" {
    description = "The name of the ECS cluster to be creatd"
    type = string
}