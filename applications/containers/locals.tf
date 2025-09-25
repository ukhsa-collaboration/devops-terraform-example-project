locals {
  ########################################################################################################
  # BEGIN SCHEDULED SHUTDOWN POLICY
  ########################################################################################################
  # Why:
  # Reduce cost in lower environments by scaling ECS services to 0 outside business hours
  # and restoring capacity at the start of the day.

  # What this does:
  # - Defines a map of scheduled actions (weekend/evening start & end) with desired min/max capacities.
  # - Intended to be passed to an ECS service module's `autoscaling_scheduled_actions` when
  #   `var.scheduled_scaledown` is true. If not enabled, pass `{}` to disable scheduling.

  # Security & ops notes:
  # - Uses "Etc/UTC" to avoid DST surprises.
  scheduled_scaledown_policy = {
    weekend_start = {
      schedule     = "cron(30 20 ? * FRI *)"
      min_capacity = 0
      max_capacity = 0
      timezone     = "Etc/UTC"
    },
    weekend_end = {
      schedule     = "cron(30 06 ? * MON *)"
      min_capacity = var.autoscaling_min_capacity
      max_capacity = var.autoscaling_max_capacity
      timezone     = "Etc/UTC"
    },
    evening_start = {
      schedule     = "cron(30 21 ? * * *)"
      min_capacity = 0
      max_capacity = 0
      timezone     = "Etc/UTC"
    },
    evening_end = {
      schedule     = "cron(30 06 ? * * *)"
      min_capacity = var.autoscaling_min_capacity
      max_capacity = var.autoscaling_max_capacity
      timezone     = "Etc/UTC"
    }
  }
  ########################################################################################################
  # END SCHEDULED SHUTDOWN POLICY
  ########################################################################################################
}