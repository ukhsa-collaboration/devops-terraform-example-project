# Hello World Service Infrastructure

This repository contains the Terraform configurations to deploy the `hello-world` service, consisting of two applications: [hello-world-frontend](https://github.com/ntsedemoorg/hello-world-front) and [hello-world-api](https://github.com/ntsedemoorg/hello-world-api). This Terraform repo will set up the necessary AWS infrastructure to run the applications, including networking, ECS, and Memcached.

## Project Structure

- `applications/`
  - `hello-world-frontend/`: Terraform configuration for deploying the frontend application.
  - `hello-world-api/`: Terraform configuration for deploying the backend API.
- `core-services/`
  - `00-network/`: Terraform configuration for setting up the network infrastructure (VPC, subnets, etc.).
  - `01-ecs/`: Terraform configuration for setting up the ECS cluster and services.
  - `02-memcached/`: Terraform configuration for setting up the Memcached instance.
- `environment/`
  - `dev.tfvars`: Terraform variables for the development environment.
  - `prod.tfvars`: Terraform variables for the production environment.
- `global.tfvars`: Global Terraform variables.
- `versions.tf`: Terraform provider and version configurations. This file is copied during the Github Actions workflow to each directory where it is needed. CLI flags are then passed in to use the correct backend.

## Order of Terraform Apply

The directories under `core-services` are prefixed with numbers (`00`, `01`, `02`, etc.) to indicate the order in which the Terraform configurations should be applied. This ensures that dependencies are correctly set up in sequence:

1. **00-network**: Sets up the foundational network infrastructure, including VPC, subnets, and related resources. This must be done first because the other services depend on the network setup.
2. **01-ecs**: Creates the ECS cluster and related services. This requires the network infrastructure to be in place.
3. **02-memcached**: Sets up the Memcached instance, which will be used by the backend API. This needs the ECS cluster to be ready for service definitions and task placements.

## Terraform State Files

Each directory in the `core-services` and `applications` folders maintains its own Terraform state file. This isolation allows for modular and independent management of each component of the infrastructure, facilitating easier updates and rollbacks.

Each state file is stored in at the key `<environment name>/<directory name>/state.tfstate`. For example, the state file for the `hello-world-api` in development would be `development/hello-world-api/state.tfstate`.
 
## Usage of Terraform AWS Modules

Where necessary and possible, this repository leverages community-maintained `terraform-aws-modules` to simplify and standardise the creation of AWS resources. These modules provide best practices, reduced boilerplate, and easier maintenance.

- [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc): Used in `00-network` to create a Virtual Private Cloud (VPC) with subnets, route tables, and other necessary components.
- [terraform-aws-ecs](https://github.com/terraform-aws-modules/terraform-aws-ecs): Used in `01-ecs` to create the ECS cluster and used in by both `hello-world-api` and `hello-world-front` to create ECS service and tasks.
- [terraform-aws-elasticache](https://github.com/terraform-aws-modules/terraform-aws-elasticache): Used in `03-memcached`

For more information on the specific modules used and their configurations, refer to the individual Terraform configuration files in each directory.