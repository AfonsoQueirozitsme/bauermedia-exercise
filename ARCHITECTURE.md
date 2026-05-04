# Architecture & Implementation Guide

This document provides a complete and detailed explanation of everything implemented in this repository — from infrastructure provisioning to application deployment and load balancing.

---

## Table of Contents

1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Infrastructure Layer (Terraform)](#infrastructure-layer-terraform)
   - [Provider Configuration](#1-provider-configuration)
   - [Variables](#2-variables)
   - [Networking](#3-networking)
   - [Compute Instances](#4-compute-instances)
   - [Load Balancer](#5-load-balancer)
   - [Outputs](#6-outputs)
4. [Kubernetes Layer (K3s)](#kubernetes-layer-k3s)
   - [Deployment](#1-deployment)
   - [Service](#2-service)
5. [How Everything Connects](#how-everything-connects)
6. [Deployment Flow](#deployment-flow)
7. [Issues Found & Fixed](#issues-found--fixed)

---

## Overview

This project implements a **fully automated cloud infrastructure** using Terraform on **Oracle Cloud Infrastructure (OCI)**, running a **K3s Kubernetes cluster** (1 Master + 1 Worker) with an **Nginx web application** (2 replicas) fronted by an **OCI Public Load Balancer**.

The entire stack is defined as Infrastructure as Code — a single `terraform apply` provisions everything from the network to the running application.

---

## Repository Structure

```
bauermedia-exercise/
├── terraform/                 # Infrastructure as Code (Terraform)
│   ├── provider.tf            # OCI + TLS provider configuration
│   ├── variables.tf           # Input variables (tenancy, user, keys, region)
│   ├── network.tf             # VCN, Subnet, Internet Gateway, Security List, Load Balancer
│   ├── compute.tf             # Master and Worker compute instances
│   └── outputs.tf             # Output values (IPs)
├── k8s/                       # Kubernetes manifests
│   ├── app.yaml               # Combined Deployment + Service (primary manifest)
│   ├── deployment.yaml         # Standalone Deployment definition
│   └── service.yaml           # Standalone Service definition
├── README.md                  # Project overview
├── requirements.md            # Exercise requirements
├── deviation.md               # Tracked deviations from requirements
└── .gitignore                 # Ignores .terraform/, state files, keys
```

---

## Infrastructure Layer (Terraform)

### 1. Provider Configuration

**File:** `terraform/provider.tf`

Two providers are used:

| Provider | Purpose |
|----------|---------|
| `hashicorp/oci` (>= 4.0.0) | Oracle Cloud Infrastructure API |
| `hashicorp/tls` (>= 4.0.0) | Generate SSH key pairs dynamically |

The OCI provider authenticates using API key credentials (tenancy OCID, user OCID, fingerprint, and a `.pem` private key file).

---

### 2. Variables

**File:** `terraform/variables.tf`

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tenancy_ocid` | string | — | OCI Tenancy OCID (required) |
| `user_ocid` | string | — | OCI User OCID (required) |
| `fingerprint` | string | — | API key fingerprint (required) |
| `region` | string | `eu-frankfurt-1` | OCI Region |
| `private_key_path` | string | `./oci_api_key.pem` | Path to OCI API private key |

These values are typically supplied via a `terraform.tfvars` file (which is `.gitignore`d for security).

---

### 3. Networking

**File:** `terraform/network.tf`

The networking layer builds a complete VCN topology:

#### VCN (Virtual Cloud Network)
- **CIDR Block:** `10.0.0.0/16`
- Provides the isolated network boundary for all resources.

#### Internet Gateway
- Attached to the VCN to allow outbound and inbound internet traffic.

#### Route Table
- Default route (`0.0.0.0/0`) pointing to the Internet Gateway.
- This ensures all instances and the Load Balancer can reach the internet.

#### Security List (Firewall Rules)

| Direction | Protocol | Port | Purpose |
|-----------|----------|------|---------|
| Ingress | TCP | 22 | SSH access to instances |
| Ingress | TCP | 80 | HTTP traffic (Load Balancer) |
| Ingress | TCP | 6443 | Kubernetes API server |
| Ingress | TCP | 30080 | NodePort for the web application |
| Egress | All | All | Unrestricted outbound traffic |

#### Subnet
- **CIDR:** `10.0.1.0/24`
- All compute instances and the Load Balancer reside in this subnet.

---

### 4. Compute Instances

**File:** `terraform/compute.tf`

Two ARM-based compute instances are provisioned:

| Instance | Shape | OCPUs | RAM | Role |
|----------|-------|-------|-----|------|
| `k3s-master` | VM.Standard.A1.Flex | 1 | 6 GB | K3s server (control plane) |
| `k3s-worker` | VM.Standard.A1.Flex | 1 | 6 GB | K3s agent (worker node) |

Both use the **Ampere A1 (ARM)** shape, which is eligible for the OCI Always Free Tier.

#### Image Selection
An Ubuntu 22.04 ARM image is automatically discovered using a regex filter:
```
^Canonical-Ubuntu-22.04-aarch64-([.0-9-]+)$
```

#### SSH Key Generation
A 4096-bit RSA key pair is generated dynamically using the `tls_private_key` resource. The public key is injected into both instances via `ssh_authorized_keys`.

#### K3s Bootstrap (user_data)

**Master node:**
```bash
#!/bin/bash
curl -sfL https://get.k3s.io | K3S_TOKEN=mysecrettoken sh -
```
- Installs K3s in **server** mode.
- Sets a fixed cluster join token (`K3S_TOKEN`) so the worker can authenticate.

**Worker node:**
```bash
#!/bin/bash
curl -sfL https://get.k3s.io | K3S_URL=https://<master_private_ip>:6443 K3S_TOKEN=mysecrettoken sh -
```
- Installs K3s in **agent** mode.
- Joins the cluster automatically using the master's private IP and the shared token.
- `K3S_URL` uses Terraform's interpolation (`${oci_core_instance.k3s_master.private_ip}`) to dynamically resolve the master's IP — this creates an implicit dependency ensuring the master is created first.

---

### 5. Load Balancer

**File:** `terraform/network.tf` (bottom section)

The OCI Load Balancer distributes incoming HTTP traffic across both K3s nodes:

```
Internet → OCI Load Balancer (port 80) → Backend Set (Round Robin) → NodePort 30080 on Master & Worker
```

| Resource | Configuration |
|----------|--------------|
| **Load Balancer** | Flexible shape, 10 Mbps bandwidth, public |
| **Backend Set** | Round Robin policy, TCP health check on port 30080 |
| **Backend (Master)** | Master's private IP, port 30080 |
| **Backend (Worker)** | Worker's private IP, port 30080 |
| **Listener** | Port 80, TCP protocol |

**How it works:** Users hit the Load Balancer's public IP on port 80. The Load Balancer distributes requests evenly (Round Robin) to port 30080 on both nodes. Port 30080 is the Kubernetes `NodePort` that routes traffic to the Nginx pods.

---

### 6. Outputs

**File:** `terraform/outputs.tf`

After `terraform apply`, the following values are displayed:

| Output | Value |
|--------|-------|
| `master_public_ip` | Public IP of the K3s master node |
| `worker_public_ip` | Public IP of the K3s worker node |
| `load_balancer_public_ip` | Public IP of the OCI Load Balancer (main entry point) |

---

## Kubernetes Layer (K3s)

### 1. Deployment

**Files:** `k8s/app.yaml` (lines 1–21), `k8s/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bauermedia-app
spec:
  replicas: 2
```

- **2 replicas** of Nginx are deployed across the cluster.
- Kubernetes will schedule the pods across available nodes (master and worker), providing redundancy.
- Uses the official `nginx:latest` image, exposing container port 80.

### 2. Service

**Files:** `k8s/app.yaml` (lines 22–35), `k8s/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: bauermedia-service
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

- **Type: NodePort** — Exposes the service on port `30080` on every node in the cluster.
- The OCI Load Balancer targets this port on both nodes.
- The fixed `nodePort: 30080` ensures predictable routing from the Load Balancer.

> **Note:** `app.yaml` is the primary manifest and contains both the Deployment and the Service in a single file (separated by `---`). The files `deployment.yaml` and `service.yaml` are standalone versions of the same resources.

---

## How Everything Connects

```
                    ┌──────────────────────────────────┐
                    │          INTERNET                 │
                    └───────────────┬──────────────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────────┐
                    │     OCI Load Balancer             │
                    │     Public IP — Port 80           │
                    │     Policy: Round Robin           │
                    └──────┬───────────────┬───────────┘
                           │               │
                    ┌──────▼──────┐ ┌──────▼──────┐
                    │ k3s-master  │ │ k3s-worker  │
                    │ Port 30080  │ │ Port 30080  │
                    │ (NodePort)  │ │ (NodePort)  │
                    └──────┬──────┘ └──────┬──────┘
                           │               │
                    ┌──────▼───────────────▼──────┐
                    │    K3s Cluster (K8s)         │
                    │  ┌─────────┐  ┌─────────┐   │
                    │  │ Nginx   │  │ Nginx   │   │
                    │  │ Pod #1  │  │ Pod #2  │   │
                    │  │ :80     │  │ :80     │   │
                    │  └─────────┘  └─────────┘   │
                    └─────────────────────────────┘
```

1. A user accesses the **Load Balancer's public IP** on port **80**.
2. The Load Balancer forwards the request to one of the two nodes on port **30080** (Round Robin).
3. The Kubernetes `NodePort` Service receives the request and routes it to one of the 2 **Nginx pods** on port **80**.
4. Nginx serves the response back through the same path.

---

## Deployment Flow

Running `terraform apply` triggers the following sequence:

1. **Network creation** — VCN, Subnet, Internet Gateway, Route Table, Security List.
2. **SSH key generation** — A fresh RSA-4096 key pair is created.
3. **Master instance** — VM is created and K3s server is installed via `user_data`.
4. **Worker instance** — VM is created (depends on master for the private IP) and K3s agent joins the cluster.
5. **Load Balancer** — Created in the subnet, with backends pointing to master and worker on port 30080.
6. **Outputs** — Master IP, Worker IP, and Load Balancer IP are displayed.

After Terraform completes, the Kubernetes manifests from `k8s/` need to be applied manually:

```bash
ssh -i <private_key> ubuntu@<master_public_ip>
sudo kubectl apply -f app.yaml
```

---

## Issues Found & Fixed

During the final review, the following issues were identified and corrected:

| # | Issue | File | Fix |
|---|-------|------|-----|
| 1 | `deployment.yaml` had `replicas: 1` while `app.yaml` had `replicas: 2` | `k8s/deployment.yaml` | Updated to `replicas: 2` for consistency |
| 2 | `tls` provider was missing from `required_providers` | `terraform/provider.tf` | Added `hashicorp/tls >= 4.0.0` — required by the `tls_private_key` resource |
| 3 | All comments and documentation were in Portuguese | All files | Translated to English |
