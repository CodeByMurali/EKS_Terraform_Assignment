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
* 📸 AWS Service Screenshots & Details

-----

## 🌟 Project Goal

This project aims to establish a scalable, and secure infrastructure on **AWS** for deploying a 3-tier **E-commerce application** that allows users to purchase robots. Our primary goal is to provision this infrastructure using **Terraform** via **GitHub Actions**, emphasizing **security best practices** and **operational efficiency**.

-----

## ✨ Architecture Overview


![image](https://github.com/user-attachments/assets/8813ee02-5c88-4afc-9d3b-2629731e6b64)



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

![image](https://github.com/user-attachments/assets/e1ec9686-2b93-4e61-b581-ec1ac0caf18e)

![image](https://github.com/user-attachments/assets/9a95ee26-4568-4cfd-b3b4-a45ddab6e9d8)



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
📁 Terraform Project Structure
Our Terraform project is organized into a modular and reusable structure, allowing for clean separation of concerns and easy management of different environments (e.g., dev, prod).
```
.
├── .github/workflows/
│   └── terraform-EKS-Hiive.yml  # GitHub Actions workflow for CI/CD
├── eks/                         # Main EKS provisioning directory
│   ├── main.tf                  # Main configuration for EKS cluster
│   ├── backend.tf               # S3 backend configuration
│   ├── dev.tfvars               # Variable values for the 'dev' environment
│   └── variables.tf             # Input variables for the EKS module
├── eks-jump/                    # Terraform for provisioning the EKS Jump Host
│   ├── backend.tf               # S3 backend configuration for jump host
│   ├── bastion-host.tf          # Defines the bastion host EC2 instance
│   ├── data_sources_jump.tf     # Data sources specific to the jump host
│   ├── dev.tfvars               # Variable values for the jump host (e.g., instance type)
│   ├── jump-tools-install.sh    # Script for installing tools on the jump host
│   ├── output.tf                # Outputs from the jump host module
│   ├── provider.tf              # AWS provider configuration for jump host
│   └── variables.tf             # Input variables for the jump host module
└── module/                      # Reusable Terraform Modules
    └── eks-module/              # Generic EKS cluster & networking module
        ├── data_sources.tf      # Defines various data sources used by the module
        ├── eks.tf               # EKS cluster and node group definitions
        ├── iam.tf               # IAM roles and policies for EKS
        ├── vpc.tf               # VPC and networking components
        ├── main.tf              # Module's main logic (orchestrates other .tf files)
        ├── variables.tf         # Module's input variables
        └── outputs.tf           # Module's output values

```

**Modularity and Reusability**
This structure heavily emphasizes modularity and reusability

---

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
![image](https://github.com/user-attachments/assets/cd80c160-db60-43d6-9115-321b189872fe)




The E-commerce Robot Store application is a **3-tier application** deployed to the EKS cluster:

  * **Docker Image**: The application's Docker image is built and **pushed to Amazon Elastic Container Registry (ECR)** for secure storage and efficient deployment.
  * **Helm Deployment**: The application is deployed onto the EKS cluster using **Helm Charts**. Helm provides a package management solution for Kubernetes, simplifying the deployment, upgrade, and management of complex applications.
  * **Access**: The application is exposed to users via a **LoadBalancer NodePort**, ensuring external accessibility.

    ```
    ubuntu@ip-10-16-18-223:~/three-tier-architecture-demo/EKS/helm$ helm install robot-shop --namespace robot-shop .
    NAME: robot-shop
    LAST DEPLOYED: Fri Jun  6 01:58:46 2025
    NAMESPACE: robot-shop
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```
    

-----

## 📸 Detailed Service-Level Screenshots & Details

**Networking layer**

**VPC, Subnet, NAT GW, IGW, Route tables**

![image](https://github.com/user-attachments/assets/1de31c93-1881-44c8-8362-1951e481cb3a)

Load balancer

![image](https://github.com/user-attachments/assets/edb64a9c-b0cf-48fb-b13c-1a6969ad2047)


**Compute**
EKS worker nodes and Jump host

![image](https://github.com/user-attachments/assets/1b34f9fb-9a5f-47aa-afa3-36d119f18ff9)


**EKS Cluster**

![image](https://github.com/user-attachments/assets/0e1a89f0-c0f4-4dbf-a090-17cfd1ac2f2b)


**Kubernetes resources**

![image](https://github.com/user-attachments/assets/65872f9b-2419-4adf-8090-f58f02589ebd)


**Managed EKS node groups**

![image](https://github.com/user-attachments/assets/38153752-b861-4152-9e21-27d9a701c952)


**Plugins**

![image](https://github.com/user-attachments/assets/df1051e5-5d9e-4c48-8d8d-d2582d3ca33c)


**Terraform apply logs**

```
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.
```

**Terraform destroy logs**

```
module.eks.aws_vpc.vpc: Destroying... [id=vpc-0df79e293b1f2256c]
module.eks.aws_vpc.vpc: Destruction complete after 1s

Destroy complete! Resources: 38 destroyed.
```

**Git hub actions - Pls refer the actions section of this repo**

![image](https://github.com/user-attachments/assets/2865ede6-5599-4d81-b037-48b15b5e2db8)


**kubernetes cluster reources**

```
ubuntu@ip-10-16-18-223:~/three-tier-architecture-demo/EKS/helm$ kubectl get all -n robot-shop
NAME                            READY   STATUS    RESTARTS   AGE
pod/cart-655b74fb49-qmlgj       1/1     Running   0          42m
pod/catalogue-b4855db44-z9m8j   1/1     Running   0          42m
pod/dispatch-845799dc84-7h2sm   1/1     Running   0          42m
pod/mongodb-69d9cf5747-c7dv5    1/1     Running   0          42m
pod/mysql-8c599b989-xk9jc       1/1     Running   0          42m
pod/payment-6589fd67f6-zld2f    1/1     Running   0          42m
pod/rabbitmq-876447689-5xrhp    1/1     Running   0          42m
pod/ratings-6fb5c59f44-2lvcg    1/1     Running   0          42m
pod/shipping-67cdd8c8c6-lmhjr   1/1     Running   0          42m
pod/user-b4977f556-8hls4        1/1     Running   0          42m
pod/web-7649bf4886-td5bq        1/1     Running   0          42m

NAME                TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                       AGE
service/cart        ClusterIP      172.20.50.86     <none>                                                                   8080/TCP                      42m
service/catalogue   ClusterIP      172.20.255.206   <none>                                                                   8080/TCP                      42m
service/dispatch    ClusterIP      None             <none>                                                                   55555/TCP                     42m
service/mongodb     ClusterIP      172.20.29.103    <none>                                                                   27017/TCP                     42m
service/mysql       ClusterIP      172.20.246.56    <none>                                                                   3306/TCP                      42m
service/payment     ClusterIP      172.20.232.179   <none>                                                                   8080/TCP                      42m
service/rabbitmq    ClusterIP      172.20.110.119   <none>                                                                   5672/TCP,15672/TCP,4369/TCP   42m
service/ratings     ClusterIP      172.20.107.41    <none>                                                                   80/TCP                        42m
service/redis       ClusterIP      172.20.86.222    <none>                                                                   6379/TCP                      42m
service/shipping    ClusterIP      172.20.124.228   <none>                                                                   8080/TCP                      42m
service/user        ClusterIP      172.20.253.93    <none>                                                                   8080/TCP                      42m
service/web         LoadBalancer   172.20.240.230   a2488b467d92846ea91f9fb95c24c315-176850280.us-east-1.elb.amazonaws.com   8080:31678/TCP                42m

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cart        1/1     1            1           42m
deployment.apps/catalogue   1/1     1            1           42m
deployment.apps/dispatch    1/1     1            1           42m
deployment.apps/mongodb     1/1     1            1           42m
deployment.apps/mysql       1/1     1            1           42m
deployment.apps/payment     1/1     1            1           42m
deployment.apps/rabbitmq    1/1     1            1           42m
deployment.apps/ratings     1/1     1            1           42m
deployment.apps/shipping    1/1     1            1           42m
deployment.apps/user        1/1     1            1           42m
deployment.apps/web         1/1     1            1           42m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/cart-655b74fb49       1         1         1       42m
replicaset.apps/catalogue-b4855db44   1         1         1       42m
replicaset.apps/dispatch-845799dc84   1         1         1       42m
replicaset.apps/mongodb-69d9cf5747    1         1         1       42m
replicaset.apps/mysql-8c599b989       1         1         1       42m
replicaset.apps/payment-6589fd67f6    1         1         1       42m
replicaset.apps/rabbitmq-876447689    1         1         1       42m
replicaset.apps/ratings-6fb5c59f44    1         1         1       42m
replicaset.apps/shipping-67cdd8c8c6   1         1         1       42m
replicaset.apps/user-b4977f556        1         1         1       42m
replicaset.apps/web-7649bf4886        1         1         1       42m
```


For detailed AWS service-level screenshots and further insights into the deployed resources, please refer to the following Notion page:

  * [https://www.notion.so/Hiive-Assesement-209c3d778a55804984b3dad8ae91ec08]

-----

## 💡 Further Extensions & Good Practices

Here are some proposals for further enhancement:

  * **GitOps with Argo CD**: Integrate **Argo CD** for a true GitOps workflow. This enables automatic deployment of code changes (after CI pipeline completion) to the Kubernetes cluster in production.
      * *Check out my other project which demonstrates this setup: [https://github.com/CodeByMurali/CICD-Project-1]*
      * *Also plese checkout my CICD pipeline with best practices usign AWS Codedeploy, Code Pipeline and Sep function: [https://github.com/CodeByMurali/AWS-CICD-StepFunction]* 
  * **Centralized Logging and Monitoring**: Implement logging and monitoring solutions (e.g., Fluent Bit, Prometheus/Grafana) for better observability.
  * **Cost Optimization**: Further optimize costs by fine-tuning EKS node group sizing and exploring intelligent autoscaling.
  * **Secrets Management**: Utilize AWS Secrets Manager or HashiCorp Vault for more secure management of application secrets.

-----
