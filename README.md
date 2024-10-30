<p align="center">
  <img src="https://k21academy.com/wp-content/uploads/2023/10/Terraform-with-AWS.webp" width="600" />
</p>
<p align="center">
    <h1 align="center">DevOps: Terraforming Mars</h1>
</p>
<p align="center">
    <em>From Code to Cloud: Managing our infras w/ Terraform</em>
</p>
<p align="center">
	<!-- local repository, no metadata badges. -->
<p>
<p align="center">
		<em>Developed with the software and tools below.</em>
</p>
<p align="center">
	<img src="https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?style=flat&logo=GNU-Bash&logoColor=white" alt="GNU%20Bash">
	<img src="https://img.shields.io/badge/YAML-CB171E.svg?style=flat&logo=YAML&logoColor=white" alt="YAML">
	<img src="https://img.shields.io/badge/Terraform-7B42BC.svg?style=flat&logo=Terraform&logoColor=white" alt="Terraform">
	<img src="https://img.shields.io/badge/Python-3776AB.svg?style=flat&logo=Python&logoColor=white" alt="Python">
	<img src="https://img.shields.io/badge/JSON-000000.svg?style=flat&logo=JSON&logoColor=white" alt="JSON">
</p>
<hr>

## 🔗 Quick Links

> - [📍 Overview](#-overview)
> - [🚀 Getting Started](#-getting-started)
>   - [⚙ Initialize Workspace](#-initialize-workspace)
>   - [🌎 Confirm Changes Locally](#-confirm-changes-locally)
>   - [🧪 Run Tests](#-run-tests)
> - [📦 Deploy Changes](#-deploy-changes)
> - [🗂️ Featured Workspaces](-featured-workspaces)

---

## 📍 Overview

This repository contains Terraform templates for automating AWS infrastructure setup using Infrastructure as Code (IaC) principles. IaC involves managing infrastructure via code files instead of manual configurations - ensuring consistency, ease of remediations and repeatability. 

With Terraform, these files define AWS resources such as servers, databases, storage etc - making it easier to automate deployment and remediations. The repository is organized for easy customization and is a valuable resource to assist us with streamlining AWS infrastructure management.

---
## 🚀 Getting Started

***Requirements***

Ensure you have the following dependencies installed on your system:
- **Terraform cli:**
  - Log into Terraform cloud:
    - [We store our Terraform State files securely in Terraform Cloud](https://www.hashicorp.com/blog/introducing-terraform-cloud-remote-state-management#:~:text=account%20here!-,Remote%20State%20Management,-State%20files%20in)
    - To use them locally 3- you need to login by running `terraform login`
        - Ask team for login credentials

### ⚙ Initialize Workspace

1. Clone the `DevOps` repo:

```sh
git clone https://github.com/richcontext/devops.git
```

2. Open/Create new workspace

```sh
# example

cd eks_commerce-engine-k8s-cluster
```

3. Initialize the workspace:

```sh
terraform init
```

### 🌎 Confirm Changes Locally

```sh
terraform plan
```

### 🧪 Run Tests

- Tests are run in the ci pipeline - via Trivy & whenever you commit locally - via `pre-commit`
- Install `pre-commit` locally to have it auto-run for each commit you run:
    ```
    brew install pre-commit
    pre-commit install
    ```
---

# 📦 Deploy Changes
![CICD Pipeline](<.img/DevOps Workflow.png>)

- ### 1. Open a new feature branch from `main` and begin making changes
  - We want to develop and test changes locally to minimize builds - when PR is open
  - Each commit will run lint-checks & testing
  > **Important:** Make sure to have pre-commit installed and running on repo - See `tests`, under the `Getting Started` section
	```
	git pull main
	git checkout -b <branch-name>
    cd <workspace_name>

    # initialize workspace
    terraform init

    # confirm changes locally
    terraform plan 
	```
	> **Recommended branch naming convention:** `<name initials>/<Jira ticket #>/<feature name>`

- ### 2. When ready - Create the Pull Request
  - This will run testing and post proposed changes to the CI Summary
    - Any failures in testing will also be posted in the CI Summary
    - You can push new commits until it passes

- ### 3. If changes look good - deploy them via PR comment
  -  **On the PR, comment `terraform apply`**
      - This will trigger the CI to deploy the changes & confirm in them the CI Summary
    - ***If you are deleting/removing a workspace:***
      - **On the PR, comment `terraform destroy`**
      - It will run a destroy operation and confirm via PR comment
      - Afterwards, manually delete workspace on [Terraform Cloud](https://app.terraform.io/app/demo_org/workspaces)
        - We made this a manual step - in case destroy process is incomplete

- ### 4. Merge the PR 
  - After confirming your changes have deployed successfully
  - ***If you have any issues with deployment, feel free to alert the team for assistance***
</details>

---

# 🗂️ Featured Workspaces

This section provides a breakdown of the featured Terraform workspaces, each designed to address specific infrastructure needs:

## `ecr_w_txt-logic/`
> **Purpose**: Manages Elastic Container Registry (ECR) resources w/ `for-each` logic looping repo names
- **Key Features**: 
  - Automates ECR repository creation
  - Implements policies for image tagging and lifecycle management
  - Makes it easy to add/remove repos dynamically line-by-line via `repos.txt` file

## `prefix-list_access/`
> **Purpose**: Centralize ingress/egress access via Prefix Lists
- **Key Features**: 
  - Facilitates VPC and network routing through prefix lists
  - Enhances security by allowing or denying traffic based on defined CIDR/IP ranges
  - Can be used to enforce VPN-Private access to critical resources like EKS, RDS, etc

## `user_access_control_GH-Postgres/`
> **Purpose**: Manages user access controls, particularly for GitHub access & Postgres access (via Doppler Secrets manager)
- **Key Features**: 
  - Configures Postgres database roles and permissions based on employee ID
  - Configures GitHub organization access by groups and roles
  - Synchronizes user access between GitHub teams and Postgres roles.

## `ec2_w_preinstall-script/`
> **Purpose**: Provisions EC2 instances with pre-installation scripts.
- **Key Features**: 
  - Creates s3 bucket that will store the custom scripts & tools
  - Creates EC2 instances w/ custom setup scripts during instance initialization.
    - Ensuring consistent custom environment across deployed instances.
  - Logic for both Windows & Linux EC2 instances deployment

## `eks_GitOps_oriented-cluster/`
> **Purpose**: Deploys an EKS cluster configured for GitOps workflows.
### 1. Networking Setup
  - **VPC Creation**: Establish a Virtual Private Cloud (VPC) alongside essential networking components necessary for hosting an Amazon Elastic Kubernetes Service (EKS) cluster.
  - **VPC Peering**: Set up peering connections to link the VPC with other VPCs, facilitating access to protected resources like RDS databases.

### 2. EKS Cluster Deployment
  - **Cluster Initialization**: Deploy an EKS cluster, complete with node groups and role-based access control (RBAC) permissions.
  - **Blueprint Deployment**: Implement an EKS blueprint that includes AWS console-managed add-ons and service accounts/roles for critical services.

### 3. GitOps Integration
  - **GitOps Configuration**: Set up GitOps workflows using ArgoCD, deploying manifests for applications and services
  - **Custom Kubernetes manifests** - not managed by ArgoCD - synced via Terraform and hosted inside the `provisioners` directory.
  - **Environment Variables**: Secret values required by manifests are securely injected via environment variables.
  
- ### 4. Continuous Cluster Management
  - **Automated Updates**: Utilize GitOps principles to automate configuration updates to the EKS cluster, ensuring seamless and continuous integration and deployment.

## `rds_prod_staging-sync/`
> **Purpose**: Manages synchronization between production and staging environments in RDS.
### 1. Networking Setup
  - **VPC Creation**: Establish a Virtual Private Cloud (VPC) alongside essential networking components necessary for hosting an Amazon Elastic Kubernetes Service (EKS) cluster.
  - **VPC Peering**: Set up peering connections to link the RDS VPC with other VPCs needing access to the private RDS clusters

### 2. RDS Deployment
  - **Production RDS Setup (`3-rds_prod.tf`)**: Deploy an Amazon RDS Aurora cluster tailored for production workloads, ensuring high availability, security, and performance.
  - **Staging RDS Setup (`4-rds_staging.tf`)**: Deploys a duplicated RDS Aurora cluster for staging (via PROD snapshot), allowing for testing and validation before changes are applied to production.

### 2. Syncs endpoint secrets (for application access)
  - Via Doppler cli - endpoints are updated in the application secrets upon deployment or endpoint-triggering change

---
