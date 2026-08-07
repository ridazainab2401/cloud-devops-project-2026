Cloud DevOps Lab 2025
This repository contains the complete infrastructure, configuration, and CI/CD setup for a modern DevOps pipeline on AWS.

Architecture Overview
The project is built on AWS with the following components:

VPC with Public and Private Subnets.
Bastion Host (EC2) in the public subnet for secure SSH access.
Application Server (EC2) in the private subnet running a Dockerized stack.
Docker Compose Stack containing Jenkins, SonarQube, Prometheus, Grafana, Nginx, and a simple Python Flask API.
Project Structure
text

.
├── terraform/          # AWS Infrastructure as Code
├── ansible/            # Server configuration and Docker setup
├── app/                # Simple Python Flask API to be deployed
├── docker-compose.yml  # Container stack definition
├── Jenkinsfile         # CI/CD Pipeline definition
└── README.md           # This guide
Setup Instructions
1. Infrastructure (Terraform)
Navigate to the terraform/ directory.
Initialize Terraform: terraform init
Review the plan: terraform plan
Apply to AWS: terraform apply
2. Configuration (Ansible)
Update ansible/inventory.ini with the EC2 IPs from Terraform outputs.
Run the playbook to configure servers: ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
3. CI/CD (Jenkins)
Access Jenkins via the Nginx reverse proxy URL.
Connect this repository via Webhooks.
The Jenkins pipeline will automatically build the app/, run SonarQube tests, and push the image to DockerHub.
Monitoring
Metrics are scraped by Prometheus and visualized in Grafana. Alerts are configured to trigger if CPU usage exceeds 70% or if Jenkins goes down.