# Azure Red Hat OpenShift (ARO) Infrastructure

Production-ready Terraform configuration for deploying Azure Red Hat OpenShift clusters with multi-environment support and network segregation.

## 🏗️ Architecture

```
1. AVM Resource Groups     → Infrastructure and ARO cluster RGs
2. AVM Virtual Network      → Control plane + Worker subnets with NSGs  
3. ARO Cluster             → 3 master nodes + initial worker pool
4. Infrastructure Nodes     → 3 dedicated nodes (tainted for system workloads)
5. Worker Segregation       → Additional worker pools across subnets
```

## 🌍 Environments

| Environment | API/Ingress | VM Sizes | Worker Subnets | Features |
|-------------|-------------|----------|----------------|----------|
| **Dev** | Public | D8s_v3/D4s_v3/D2s_v3 | 1 | Basic setup |
| **Staging** | Private | D8s_v3/D4s_v3/D4s_v3 | 2 | Pre-prod testing |
| **Production** | Private + FIPS | D16s_v3/D8s_v3/D8s_v3 | 3 | HA + encryption |

## 📋 Prerequisites

### 1. Azure Service Principals

You need **two** service principals:

#### **Terraform Service Principal** (for infrastructure deployment)
```bash
az ad sp create-for-rbac --name "terraform-aro-sp" \\
  --role="Contributor" \\
  --scopes="/subscriptions/<SUBSCRIPTION_ID>"
```

#### **ARO Service Principal** (for cluster management)
```bash
az ad sp create-for-rbac --name "aro-cluster-sp" \\
  --role="Contributor" \\
  --scopes="/subscriptions/<SUBSCRIPTION_ID>"

# Grant additional permissions
az role assignment create \\
  --assignee <ARO_SP_APP_ID> \\
  --role "User Access Administrator" \\
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### 2. Red Hat Pull Secret

Get your pull secret from: https://console.redhat.com/openshift/install/azure/aro-provisioned

Save as `pull-secret.json` in the `aro-terraform/` directory.

### 3. Azure Subscription

- Active Azure subscription
- Quota for Standard_D8s_v3 VMs (at least 24 cores)
- Resource providers registered:
  ```bash
  az provider register -n Microsoft.RedHatOpenShift
  az provider register -n Microsoft.Network
  az provider register -n Microsoft.Storage
  ```

## 🚀 Quick Start

### Local Deployment

```bash
# Clone repository
git clone https://github.com/sanjit-web/Terraform_aro.git
cd Terraform_aro/aro-terraform

# Initialize Terraform
terraform init

# Select environment and plan
terraform plan -var-file="environments/dev/terraform.tfvars"

# Deploy
terraform apply -var-file="environments/dev/terraform.tfvars"

# Get cluster credentials
az aro list-credentials \\
  --name aro-dev-eastus \\
  --resource-group rg-aro-dev-eastus
```

### GitHub Actions Deployment

#### **Step 1: Configure Secrets**

Go to **Settings → Secrets and variables → Actions** and add:

```
ARM_CLIENT_ID          = <terraform-sp-client-id>
ARM_CLIENT_SECRET      = <terraform-sp-client-secret>
ARM_SUBSCRIPTION_ID    = <azure-subscription-id>
ARM_TENANT_ID          = <azure-tenant-id>

ARO_SP_CLIENT_ID       = <aro-sp-client-id>
ARO_SP_CLIENT_SECRET   = <aro-sp-client-secret>
ARO_SP_OBJECT_ID       = <aro-sp-object-id>

ARO_PULL_SECRET        = <red-hat-pull-secret-json>
```

#### **Step 2: Workflow Process**

1. **Create Feature Branch** → Make changes
2. **Push & Create PR** → `terraform-plan.yml` runs automatically
3. **Review Plan** → Validates dev/stg/prod configurations
4. **Merge to Main** → `terraform-apply.yml` deploys to dev
5. **Manual Trigger** → Deploy stg/prod via Actions tab

## 📁 Repository Structure

```
aro-terraform/
├── .github/workflows/          # GitHub Actions CI/CD
├── environments/               # Environment-specific configs
│   ├── dev/
│   ├── stg/
│   └── prod/
├── locals.tf                   # Environment logic
├── variables.tf                # Input variables
├── resources.tf                # Resource groups & identity
├── networking.tf               # VNet, subnets, NSGs
├── aro.tf                      # ARO cluster
├── aroinfra.tf                 # Infrastructure + worker nodes
├── outputs.tf                  # Output values
├── data.tf                     # Data sources
└── provider.tf                 # Provider configuration
```

## 🔧 Network Segregation

Worker pools are isolated in dedicated subnets:

- **worker-1**: Frontend tier (web apps, ingress)
- **worker-2**: Backend tier (APIs, microservices)
- **worker-3**: Data tier (databases, stateful services)

Deploy workloads to specific tiers using node selectors:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
spec:
  template:
    spec:
      nodeSelector:
        subnet: worker-2  # Deploy to backend tier
```

## 💰 Cost Estimation

| Environment | Monthly Cost (USD) | Components |
|-------------|-------------------:|------------|
| **Dev** | ~$400 | 3 masters + 2 workers + 2 infra |
| **Staging** | ~$800 | 3 masters + 7 workers + 3 infra |
| **Production** | ~$1,500 | 3 masters + 12 workers + 3 infra |

## 🔒 Security

### Network Security
- NSGs configured on all subnets
- Private API/Ingress for staging/production
- Service endpoints for Azure services
- ARO delegations on all subnets

### Production Compliance
- FIPS 140-2 enabled
- Encryption at host enabled
- Private endpoints
- Azure Policy integration ready

## 🐛 Troubleshooting

### Access Cluster

```bash
# List credentials
az aro list-credentials --name <cluster-name> --resource-group <rg-name>

# Get console URL
az aro show --name <cluster-name> --resource-group <rg-name> --query "consoleProfile.url" -o tsv

# Login with oc CLI
oc login <api-server-url> --username kubeadmin --password <password>
```

## 📚 Resources

- [Azure Red Hat OpenShift Documentation](https://docs.microsoft.com/en-us/azure/openshift/)
- [OpenShift Container Platform](https://docs.openshift.com/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Verified Modules](https://aka.ms/avm)

---

**Built with ❤️ using Terraform & Azure Verified Modules**

