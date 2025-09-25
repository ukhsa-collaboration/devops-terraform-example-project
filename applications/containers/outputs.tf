output "frontend_lb_dns_name" {
  description = "DNS name of the frontend ALB"
  value       = module.alb.dns_name
}