output "master_public_ip" {
  value = oci_core_instance.k3s_master.public_ip
}

output "worker_public_ip" {
  value = oci_core_instance.k3s_worker.public_ip
}

output "load_balancer_public_ip" {
  value = oci_load_balancer_load_balancer.k3s_lb.ip_address_details[0].ip_address
}
