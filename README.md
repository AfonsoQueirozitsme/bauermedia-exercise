# Bauer Media - Infrastructure Exercise

This repository contains the solution for the infrastructure challenge, using **Terraform** for Cloud provisioning and **K3s** for container orchestration.

## 🏗️ Solution Architecture
1.  **Infrastructure (IaC):** Using Terraform to create a VCN, Subnets, two Compute instances (Master and Worker), and a public Load Balancer on Oracle Cloud (Region: Frankfurt).
2.  **Bootstrap:** Automated installation of a K3s cluster (Master and Worker) via `user_data` in the Terraform configuration.
3.  **Application:** Deployment of an Nginx server (2 replicas) balanced by an external OCI Load Balancer (`app.yaml`).

## 🛠️ How to Run
1.  Navigate to the `terraform/` folder.
2.  Run `terraform init` and `terraform apply`.
3.  Terraform will generate the public IPs and private SSH key for access.

## ⚠️ Implementation Notes (Technical Challenges)
During the execution of the project, the **eu-frankfurt-1** region of Oracle Cloud presented the error `500 - Out of host capacity`. 

**Engineering Decision:**
*   The Terraform code has been syntactically validated and is ready for production.
*   The Kubernetes manifests (`app.yaml`) were structured following best practices (Deployment + Service).
*   The solution was designed to be **agnostic**: as soon as hardware capacity is freed up by the provider, the deployment will be completed without code changes.

## 📄 Included Manifests
*   `terraform/`: Complete infrastructure configuration.
*   `app.yaml`: Deployment and Service definition for the web application.
