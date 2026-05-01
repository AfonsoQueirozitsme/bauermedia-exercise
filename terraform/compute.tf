# 1. Search for the correct image (trying the ARM version which is common in the Free Tier)
data "oci_core_images" "ubuntu_image" {
  compartment_id   = var.tenancy_ocid
  operating_system = "Canonical Ubuntu"
  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-22.04-aarch64-([.0-9-]+)$"]
    regex  = true
  }
}

# 2. Generate SSH keys
resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 3. Get Availability Domain
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# 4. Create the Master Instance (Adjusted for the Ampere ARM Shape - more common in the Free Tier)
resource "oci_core_instance" "k3s_master" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.tenancy_ocid
  display_name        = "k3s-master"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  source_details {
    source_id   = data.oci_core_images.ubuntu_image.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.k3s_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.k3s_key.public_key_openssh
    user_data           = base64encode(<<-EOT
      #!/bin/bash
      curl -sfL https://get.k3s.io | K3S_TOKEN=mysecrettoken sh -
    EOT
    )
  }
}

# 5. Create the Worker Instance
resource "oci_core_instance" "k3s_worker" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.tenancy_ocid
  display_name        = "k3s-worker"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  source_details {
    source_id   = data.oci_core_images.ubuntu_image.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.k3s_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.k3s_key.public_key_openssh
    user_data           = base64encode(<<-EOT
      #!/bin/bash
      curl -sfL https://get.k3s.io | K3S_URL=https://${oci_core_instance.k3s_master.private_ip}:6443 K3S_TOKEN=mysecrettoken sh -
    EOT
    )
  }
}
