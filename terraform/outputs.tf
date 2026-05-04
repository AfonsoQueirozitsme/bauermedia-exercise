output "master_public_ip" {
  value = aws_instance.k3s_master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.k3s_worker.public_ip
}

output "load_balancer_dns" {
  value = aws_lb.k3s_alb.dns_name
}

output "private_key" {
  value     = tls_private_key.k3s_key.private_key_pem
  sensitive = true
}
