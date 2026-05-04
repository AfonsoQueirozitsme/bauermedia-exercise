# Infrastructure Engineer Exercise Presentation
## Afonso Queiroz

---

## Slide 1: Title
**Project:** Automated Web Hosting Environment
**Objective:** Deploying a resilient, automated K3s cluster on AWS
**Candidate:** Afonso Queiroz
**Technologies:** Terraform, AWS, K3s, Nginx

---

## Slide 2: Objective & Requirements
*   **Automation:** 100% Infrastructure as Code (IaC) using Terraform.
*   **Orchestration:** K3s Kubernetes cluster (1 Master + 1 Worker).
*   **Availability:** Functional website with AWS ALB Load Balancing.
*   **Self-Contained:** Everything from networking to app deployment is automated.

---

## Slide 3: Architecture Overview
*   **Cloud Provider:** Amazon Web Services (AWS).
*   **Compute:** EC2 t4g.small ARM Graviton instances.
*   **Hierarchy:**
    *   **VPC:** Virtual Private Cloud for isolation.
    *   **Cluster:** K3s Control Plane and Worker.
    *   **External Access:** Application Load Balancer (ALB).

---

## Slide 4: Networking & Security Layer
*   **VPC Topology:** CIDR `10.0.0.0/16` with 2 public subnets across AZs.
*   **Internet Gateway:** Provides external connectivity.
*   **Security Groups:**
    *   **Port 22:** SSH Management.
    *   **Port 80:** Public Web Traffic.
    *   **Port 6443:** K8s API Access.
    *   **Port 30080:** NodePort mapping for the application.

---

## Slide 5: Infrastructure as Code (Terraform)
*   **Providers:** `aws` (Infrastructure) and `tls` (Security).
*   **Dynamic Assets:** Automated RSA-4096 SSH key generation via AWS Key Pair.
*   **Resource Management:** Automated provisioning of VPC, Subnets, Gateways, and EC2 Instances.
*   **Outputs:** Instant feedback with Master IP, Worker IP, and ALB DNS name.

---

## Slide 6: Kubernetes Layer: K3s
*   **Choice:** K3s for its lightweight nature and efficiency on ARM Graviton.
*   **Bootstrap Logic:**
    *   **Master:** Installed via `user_data` script in server mode.
    *   **Worker:** Dynamically joins the cluster using the Master's private IP and a shared secret.
*   **Zero Manual Setup:** The cluster is ready to use immediately after Terraform completes.

---

## Slide 7: Application Deployment
*   **Workload:** Nginx Web Server serving a functional website.
*   **High Availability:** 2 Replicas distributed across the cluster nodes.
*   **Kubernetes Manifests:**
    *   **Deployment:** Manages pod lifecycle and scaling.
    *   **Service (NodePort):** Exposes the application on a fixed port (30080) across all nodes.

---

## Slide 8: External Load Balancing
*   **AWS Application Load Balancer (ALB):** Distributed public entry point.
*   **Traffic Flow:**
    1.  User hits ALB DNS Name (Port 80).
    2.  ALB performs HTTP health checks.
    3.  Traffic forwarded to EC2 instances on Port 30080.
    4.  Kubernetes routes traffic to the Nginx Pods.

---

## Slide 9: Technical Rationale
*   **Why AWS Graviton?** Best performance/cost ratio with ARM-based processors.
*   **Why K3s?** Minimal footprint, fast startup, and fully CNCF-compliant.
*   **Why NodePort + ALB?** Bridges the gap between cloud infra and K8s services simply and reliably for demonstration purposes.

---

## Slide 10: Conclusion & Demo
*   **Summary:** A robust, repeatable, and scalable web hosting solution.
*   **Demo Steps:**
    *   Review `terraform apply` output.
    *   Access the K3s Master via SSH.
    *   Verify pod status with `kubectl get pods`.
    *   Live access to the website via the ALB DNS name.
*   **Q&A**
