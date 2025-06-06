Here's a shortened and refined GitHub README for your EKS architecture:

-----

# 🤖 AWS EKS Provisioning with Terraform and Helm 🚀

-----

## Table of Contents

* 🌟 Project Goal
* ✨ Architecture Overview
* 🚀 Infrastructure Provisioning
* 🌐 AWS Networking Layer
* 💻 EKS Cluster Details
* 🔐 Security Best Practices
* 📦 Application Deployment
* 💡 Further Extensions & Good Practices
* 📸 Service-Level Screenshots & Details

-----

## 🌟 Project Goal

This project aims to establish a robust, scalable, and secure infrastructure on **AWS** for deploying a 3-tier **E-commerce application** that allows users to purchase robots. Our primary goal is to provision this infrastructure using **Terraform** via **GitHub Actions**, emphasizing **security best practices** and **operational efficiency**.

-----

## ✨ Architecture Overview


![image](https://github.com/user-attachments/assets/44358cb6-5952-450b-8a19-0a61fef67ec3)


The architecture provisions a AWS EKS environment to host an E-commerce application within an **Amazon Elastic Kubernetes Service (EKS)** cluster. Key components include:

  * **Custom AWS Networking**: A dedicated VPC with public and private subnets, Internet Gateway, NAT Gateway, and route tables.
  * **EKS Cluster**: A highly available Kubernetes cluster with worker nodes residing in private subnets.
  * **Jump Host**: A bastion instance provisioned in a public subnet to securely access the EKS cluster and private worker nodes.
  * **E-commerce Application**: A 3-tier application deployed to EKS using Helm, exposed via a LoadBalancer NodePort.
  * **ECR Integration**: Docker image for the application are pushed to Amazon Elastic Container Registry (ECR).

-----

## 🚀 Infrastructure Provisioning

Our entire infrastructure is provisioned using **Terraform**, ensuring infrastructure-as-code principles are followed for reproducibility and version control.

### GitHub Actions Workflow 🤖

The infrastructure deployment is fully automated through a **GitHub Actions workflow**. This workflow provides a interface to manage the infrastructure:

  * **`terraform plan`**: Allows users to preview infrastructure changes before applying them.
  * **`terraform apply`**: Executes the planned changes to provision or update the AWS resources.
  * **`terraform destroy`**: Safely tears down the entire infrastructure.

Each action includes a **validation step** to ensure code quality and configuration correctness.

### Terraform Backend Configuration

Terraform state is securely managed in an **S3 bucket** with **DynamoDB locking** to prevent concurrent modifications.

```terraform
terraform {
  required_version = "~> 1.12.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }

  backend "s3" {
    bucket         = "use1-remote-terraform-state-file-bucket-murali"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

-----

## 🌐 AWS Networking Layer

A robust and secure networking setup is provisioned for the EKS cluster:

  * **Virtual Private Cloud (VPC)**
  * **Public Subnets (3)**: These host the Internet Gateway, NAT Gateway, and the Jump Host.
  * **Private Subnets (3)**: All EKS worker nodes reside in these private subnets for enhanced security.
  * **Internet Gateway (IGW)**: For outbound internet access from public subnets.
  * **NAT Gateway (NGW)**: Deployed in a public subnet with an associated Elastic IP to provide outbound internet access for resources in private subnets (e.g., EKS worker nodes).
  * **Route Tables**: Separate public and private route tables manage traffic flow.
  * **Security Groups**: Fine-grained access control, including an EKS cluster security group (`eks-sg`) that allows port 443 traffic only from the Jump Host.

-----

## 💻 EKS Cluster Details

The core of our infrastructure is the Amazon EKS cluster:

  * **EKS Cluster Version**: **`1.33`**
  * **EKS Addons and Versions**:
      * `vpc-cni`: `v1.19.5-eksbuild.1`
      * `coredns`: `v1.12.1-eksbuild.2`
      * `kube-proxy`: `v1.33.0-eksbuild.2`
      * `aws-ebs-csi-driver`: `v1.44.0-eksbuild.1`
  * **Endpoint Access**: The cluster has **private access enabled** and **public access disabled**. This ensures that direct access to the EKS API server is restricted to within the VPC, significantly enhancing security.
  * **Worker Node Groups**:
      * **On-Demand Nodes**: `t3a.medium` instances with defined scaling capacities.
      * **Spot Nodes**: Various instance types for cost savings, with defined scaling capacities.
  * **Jump Host**: To interact with the EKS cluster and worker nodes (which are in private subnets), a dedicated **jump host** is provisioned in a public subnet. All access to the EKS cluster is routed through this secure jump instance.

-----

## 🔐 Security Best Practices

Security is important for any architecture:

  * **Least Privilege Principle**: All IAM roles (EKS cluster role, NodeGroup role, OIDC role) are configured with the **least privilege necessary** to perform their functions.
  * **Private Worker Nodes**: EKS worker nodes are placed in **private subnets**, preventing direct internet exposure.
  * **Restricted EKS Endpoint Access**: The EKS cluster API endpoint is configured for private access only, accessible via the Jump Host.
  * **OIDC Provider Integration**: EKS integrates with an IAM OIDC provider for granular permissions to Kubernetes service accounts, allowing pods to assume specific IAM roles. An example policy attached to this OIDC role provides S3 bucket listing permissions.
  * **Security Groups**: Strict security group rules control ingress and egress traffic for the EKS cluster and other resources.

-----

## 📦 Application Deployment

![image](https://github.com/user-attachments/assets/7cf3e33b-8c59-4876-99b5-03250867ddd6)


The E-commerce Robot Store application is a **3-tier application** deployed to the EKS cluster:

  * **Docker Image**: The application's Docker image is built and **pushed to Amazon Elastic Container Registry (ECR)** for secure storage and efficient deployment.
  * **Helm Deployment**: The application is deployed onto the EKS cluster using **Helm Charts**. Helm provides a robust package management solution for Kubernetes, simplifying the deployment, upgrade, and management of complex applications.
  * **Access**: The application is exposed to users via a **LoadBalancer NodePort**, ensuring external accessibility.

-----

## 💡 Further Extensions & Good Practices

Here are some proposals for further enhancement:

  * **GitOps with Argo CD**: Integrate **Argo CD** for a true GitOps workflow. This enables automatic deployment of code changes (after CI pipeline completion) to the Kubernetes cluster in production.
      * *Check out my other project which demonstrates this setup: [https://github.com/CodeByMurali/CICD-Project-1]*
      * *Also plese checkout my CICD pipeline with best practices usign AWS Codedeploy, Code Pipeline and Sep function: [https://github.com/CodeByMurali/AWS-CICD-StepFunction]* 
  * **Centralized Logging and Monitoring**: Implement robust logging and monitoring solutions (e.g., Fluent Bit, Prometheus/Grafana) for better observability.
  * **Cost Optimization**: Further optimize costs by fine-tuning EKS node group sizing and exploring intelligent autoscaling.
  * **Secrets Management**: Utilize AWS Secrets Manager or HashiCorp Vault for more secure management of application secrets.

-----

## 📸 Eash AWS Service-Level Screenshots & Details

For detailed AWS service-level screenshots and further insights into the deployed resources, please refer to the following Notion page:

  * [https://www.notion.so/Hiive-Assesement-209c3d778a55804984b3dad8ae91ec08]

-----
