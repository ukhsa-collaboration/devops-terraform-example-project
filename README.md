# Hello World Service Infrastructure

This repository contains the Terraform configurations to deploy the `hello-world` service, consisting of two applications: [hello-world-frontend](https://github.com/ntsedemoorg/hello-world-front) and [hello-world-api](https://github.com/ntsedemoorg/hello-world-api). This Terraform repo sets up the necessary AWS infrastructure to run the applications, including networking, ECS, and Memcached.

## Project Structure

- `applications/`
  - `hello-world-frontend/`: Terraform configuration for deploying the frontend application.
  - `hello-world-api/`: Terraform configuration for deploying the backend API.
- `core-services/`
  - `network/`: Terraform configuration for setting up the network infrastructure (VPC, subnets, etc.).
  - `ecs/`: Terraform configuration for setting up the ECS cluster and services.
  - `memcached/`: Terraform configuration for setting up the Memcached instance.
- `environment/`
  - `dev.tfvars`: Terraform variables for the development environment.
  - `prod.tfvars`: Terraform variables for the production environment.
- `global.tfvars`: Global Terraform variables.
- `providers.tf`: Terraform provider configurations. If this file doesn't exist within the stack directory, the providers.tf at the root of the directory is copied during the Github Actions workflow to where it is needed. CLI flags are then passed in to use the correct backend.
- `terraform.tf`: Terraform version configuration. If this file doesn't exist within the stack directory, the terraform.tf at the root of the directory is copied during the Github Actions workflow to where it is needed.

## Terraform Stacks

Each directory in the `core-services` and `applications` folders has its own Terraform state file. Each directory is called a 'stack'. This isolation allows for modular and independent management of each component of the infrastructure, facilitating easier updates and rollbacks.

With an AWS S3 backend, the state file for each stack is stored in at the key `<environment name>/<directory name>/state.tfstate` in the state bucket. For example, the state file for the `hello-world-api` stack in the `development` environment would be `development/hello-world-api/state.tfstate`.

## Order of Terraform Apply / `dependencies.json`

In each Terraform stack, there is a `dependencies.json`. This **MUST** exist in each stack that you want to deploy. The content of this looks similar to the below and represents the direct dependencies of each stack. The [terraform-dependency-sort](https://github.com/ukhsa-collaboration/devops-github-actions/tree/main/.github/actions/terraform-dependency-sort) action finds indirect dependencies of each stack and return a list of stacks, topgraphically sorted into the order it must be applied. This is then used by Github Actions to run the Terraform commands in the correct order of dependency.

The dependencies.json **MUST** validate against the schema below. If there are no dependencies, `paths` can be a blank array.

### Schema

```json
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "Dependencies Schema",
    "type": "object",
    "properties": {
        "dependencies": {
            "type": "object",
            "properties": {
                "paths": {
                    "type": "array",
                    "items": {
                        "type": "string",
                    },
                }
            },
            "required": ["paths"],
        }
    },
    "required": ["dependencies"],
```

### Example of a stack with dependencies

```json
{
    "dependencies": {
        "paths": [
            "./core-services/ecs",
            "./core-services/memcached"
        ]
    }
}
```

### Example of a stack with zero dependencies

```json
{
    "dependencies": {
        "paths": []
    }
}
```

## Usage of Terraform AWS Modules

Where necessary and possible, this repository leverages community-maintained `terraform-aws-modules` to simplify and standardise the creation of AWS resources. These modules provide best practices, reduced boilerplate, and easier maintenance.

- [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc): Used in `network` to create a Virtual Private Cloud (VPC) with subnets, route tables, and other necessary components.
- [terraform-aws-ecs](https://github.com/terraform-aws-modules/terraform-aws-ecs): Used in `ecs` to create the ECS cluster and used in by both `hello-world-api` and `hello-world-front` to create ECS service and tasks.
- [terraform-aws-elasticache](https://github.com/terraform-aws-modules/terraform-aws-elasticache): Used in `memcached`

For more information on the specific modules used and their configurations, refer to the individual Terraform configuration files in each directory.
