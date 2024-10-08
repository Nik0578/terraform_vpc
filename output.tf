output "load_balancer_arn" {
  value = aws_lb.my_alb.arn
}

# Output the Load Balancer DNS Name
output "load_balancer_dns_name" {
  value = aws_lb.my_alb.dns_name
}

# Output the Load Balancer Name
output "load_balancer_name" {
  value = aws_lb.my_alb.name
}