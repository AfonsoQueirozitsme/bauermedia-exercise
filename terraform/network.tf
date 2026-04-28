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

# 4. Security List (Corrigido sem o caractere ";")
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
