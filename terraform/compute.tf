# 1. Using a static Ubuntu 22.04 ARM AMI ID for us-east-1
variable "ubuntu_ami" {
  default = "ami-0a0c8eebcdd6dcbd0"
}

# 2. Generate SSH keys
resource "tls_private_key" "k3s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k3s_key" {
  key_name   = "k3s-key"
  public_key = tls_private_key.k3s_key.public_key_openssh
}

# 3. Create the Master Instance
resource "aws_instance" "k3s_master" {
  ami                    = var.ubuntu_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k3s_subnet_a.id
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  key_name               = aws_key_pair.k3s_key.key_name

  user_data = <<-EOT
    #!/bin/bash
    # 1. Prepare application manifest for K3s auto-deployment
    mkdir -p /var/lib/rancher/k3s/server/manifests
    cat <<'EOF' > /var/lib/rancher/k3s/server/manifests/app.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bauermedia-app
      labels:
        app: bauermedia
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: bauermedia
      template:
        metadata:
          labels:
            app: bauermedia
        spec:
          containers:
          - name: nginx
            image: nginx:latest
            ports:
            - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: bauermedia-service
    spec:
      selector:
        app: bauermedia
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
          nodePort: 30080
      type: NodePort
    EOF

    # 2. Install K3s (will auto-deploy the manifest above)
    curl -sfL https://get.k3s.io | K3S_TOKEN=mysecrettoken sh -
  EOT

  tags = {
    Name = "k3s-master"
  }
}

# 4. Create the Worker Instance
resource "aws_instance" "k3s_worker" {
  ami                    = var.ubuntu_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.k3s_subnet_b.id
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  key_name               = aws_key_pair.k3s_key.key_name

  user_data = <<-EOT
    #!/bin/bash
    curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=mysecrettoken sh -
  EOT

  tags = {
    Name = "k3s-worker"
  }
}
