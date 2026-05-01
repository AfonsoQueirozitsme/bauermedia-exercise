# 1. VCN
resource "oci_core_vcn" "k3s_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.tenancy_ocid
  display_name   = "k3s-vcn"
  dns_label      = "k3s"
}

# 2. Internet Gateway
resource "oci_core_internet_gateway" "k3s_ig" {
  compartment_id = var.tenancy_ocid
  display_name   = "k3s-internet-gateway"
  vcn_id         = oci_core_vcn.k3s_vcn.id
}

# 3. Route Table
resource "oci_core_default_route_table" "k3s_rt" {
  manage_default_resource_id = oci_core_vcn.k3s_vcn.default_route_table_id
  display_name               = "k3s-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.k3s_ig.id
  }
}

# 4. Security List
resource "oci_core_default_security_list" "k3s_sl" {
  manage_default_resource_id = oci_core_vcn.k3s_vcn.default_security_list_id
  display_name               = "k3s-security-list"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 30080
      max = 30080
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# 5. Subnet
resource "oci_core_subnet" "k3s_subnet" {
  cidr_block        = "10.0.1.0/24"
  display_name      = "k3s-subnet"
  compartment_id    = var.tenancy_ocid
  vcn_id            = oci_core_vcn.k3s_vcn.id
  route_table_id    = oci_core_vcn.k3s_vcn.default_route_table_id
  security_list_ids = [oci_core_vcn.k3s_vcn.default_security_list_id]
  dns_label         = "k3ssubnet"
}

# 6. Load Balancer
resource "oci_load_balancer_load_balancer" "k3s_lb" {
  compartment_id = var.tenancy_ocid
  display_name   = "k3s-lb"
  shape          = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
  subnet_ids = [oci_core_subnet.k3s_subnet.id]
  is_private = false
}

resource "oci_load_balancer_backend_set" "k3s_bes" {
  load_balancer_id = oci_load_balancer_load_balancer.k3s_lb.id
  name             = "k3s-bes"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 30080
  }
}

resource "oci_load_balancer_backend" "master_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.k3s_lb.id
  backendset_name  = oci_load_balancer_backend_set.k3s_bes.name
  ip_address       = oci_core_instance.k3s_master.private_ip
  port             = 30080
}

resource "oci_load_balancer_backend" "worker_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.k3s_lb.id
  backendset_name  = oci_load_balancer_backend_set.k3s_bes.name
  ip_address       = oci_core_instance.k3s_worker.private_ip
  port             = 30080
}

resource "oci_load_balancer_listener" "k3s_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.k3s_lb.id
  name                     = "k3s-listener"
  default_backend_set_name = oci_load_balancer_backend_set.k3s_bes.name
  port                     = 80
  protocol                 = "TCP"
}
