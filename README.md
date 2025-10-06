# Hello World Service Infrastructure

This repository contains the Terraform configurations to deploy the `hello-world` service, consisting of two applications: [hello-world-front](https://github.com/ukhsa-collaboration/devops-hello-world-front) and [hello-world-api](https://github.com/ukhsa-collaboration/devops-hello-world-api). This Terraform repo sets up the necessary AWS infrastructure to run the applications.

## Project Structure

- `applications/`
  - `containers/`: Terraform configuration for deploying the frontend and backend applications.
- `core-services/`
  - `network/`: Terraform configuration for setting up the network infrastructure (VPC, subnets, etc.).
  - `ecs/`: Terraform configuration for setting up the ECS cluster and services.
- `environment/`
  - `dev.tfvars`: Terraform variables for the development environment.
- `global.tfvars`: Global Terraform variables.

## Terraform Stacks

Each directory in the `core-services` and `applications` folders has its own Terraform state file. Each directory is called a 'stack'. This isolation allows for modular and independent management of each component of the infrastructure, facilitating easier updates and rollbacks.

With an AWS S3 backend, the state file for each stack is stored in at the key `<environment name>/<directory name>/state.tfstate` in the state bucket. For example, the state file for the `containers` stack in the `dev` environment would be `dev/containers/state.tfstate`.

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
            "./core-services/ecs"
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
