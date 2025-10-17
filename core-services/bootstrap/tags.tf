provider "aws" {
  default_tags {
    tags = local.default_tags
  }
}

locals {

  environment_names = {
    "prd" = "Production"
    "uat" = "PreProduction"
    "dev" = "Development"
  }

  environment_schedules = {
    "prd" = "24x7"
    "uat" = "24x7"
    "dev" = "OfficeHours"
  }

  stack_name = basename(path.cwd)

  mandatory_ukhsa_tags = {
    "lz:TechOwner"                        = "Sebastian.Weavers@ukhsa.gov.uk"
    "lz:BusinessOwner"                    = "Sebastian.Weavers@dhsc.gov.uk"
    "lz:CostCode"                         = "R000"
    "lz:BackupPlan"                       = "None"
    "lz:GovernmentSecurityClassification" = "OFFICIAL"
    "lz:Service"                          = "Hello World"
    "lz:Environment"                      = lookup(local.environment_names, var.environment_name, "Sandbox")
    "lz:SupportTier"                      = "Wood"
    "lz:Team"                             = "Cloud Platform Team"
    "lz:Notification"                     = "devopsengineeringteam@ukhsa.gov.uk"
    "lz:LeanIXId"                         = "0000000000000000"
  }

  optional_ukhsa_tags = {
    "lz:Schedule"           = lookup(local.environment_schedules, var.environment_name, "OfficeHours")
    "lz:DataClassification" = "Corporate"
    "lz:HealthData"         = "False"
  }

  optional_tags = {
    "X:SourceCode"     = "https://github.com/ukhsa-collaboration/devops-terraform-example-project"
    "X:TerraformStack" = local.stack_name
  }

  default_tags = merge(local.mandatory_ukhsa_tags, local.optional_ukhsa_tags, local.optional_tags)
}
