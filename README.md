# Bauer Media - Infrastructure Exercise

This repository contains the solution for the infrastructure challenge, using **Terraform** for Cloud provisioning and **K3s** for container orchestration.

## 🏗️ Solution Architecture
1.  **Infrastructure (IaC):** Using Terraform to create a VPC, Subnets (2 AZs), Security Groups, two EC2 instances (Master and Worker), and a public Application Load Balancer on AWS (Region: Ireland).
2.  **Bootstrap:** Automated installation of a K3s cluster (Master and Worker) via `user_data` in the Terraform configuration.
3.  **Application:** Deployment of an Nginx server (2 replicas) balanced by an AWS ALB (`app.yaml`).

## 🛠️ How to Run
1.  Configure AWS credentials (`aws configure` or environment variables).
2.  Navigate to the `terraform/` folder.
3.  Run `terraform init` and `terraform apply`.
4.  Terraform will generate the EC2 public IPs, ALB DNS name, and private SSH key.

## 📄 Included Manifests
*   `terraform/`: Complete AWS infrastructure configuration.
*   `k8s/app.yaml`: Deployment and Service definition for the web application.
*   `presentation/`: Interactive HTML presentation (Reveal.js).
