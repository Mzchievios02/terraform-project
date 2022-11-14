output "alb_dns_name" {
  value       = module.webserver_cluser.alb_dns_name
  description = "The domain name of the load balancer"
}