# Azure Red Hat OpenShift (ARO) - Terraform Infrastructure

A clean, production-ready Terraform configuration to deploy Azure Red Hat OpenShift with network segregation and infrastructure node pools.

## What This Does

This Terraform project automates the deployment of an ARO cluster with a specific workflow:

1. **Creates the Network Foundation**
   - A virtual network (VNet) for your ARO cluster
   - One control plane subnet for ARO masters
   - Multiple worker subnets for node segregation

2. **Deploys the ARO Cluster**
   - Provisions an Azure Red Hat OpenShift cluster
   - Uses service principal authentication
   - Connects to the control plane subnet

3. **Sets Up Machine Pools**
   - Creates a dedicated **infra machine pool** for infrastructure workloads (monitoring, logging, routing)
   - Creates **worker machine pools** - one per worker subnet
   - Each worker pool is isolated in its own subnet for network segregation

4. **Optional Components**
   - Storage account for container registry or backups
   - DNS zone for custom domains
   - Azure Front Door for global load balancing

## Why Network Segregation?

By creating one worker machine pool per subnet, you can:
- Isolate workloads by network boundaries
- Apply different network security rules per subnet
- Control traffic flow between application tiers
- Meet compliance requirements for network isolation

## Quick Start

### Prerequisites

1. Azure subscription with sufficient quota for ARO
2. Azure CLI installed and logged in
3. Red Hat pull secret from https://cloud.redhat.com/openshift/install/azure/aro-provisioned
4. Terraform 1.5+ installed

### Step 1: Configure Your Variables

```bash
# Copy the example file
cp terraform.tfvars.temp terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Fill in these required values:
- `subscription_id` - Your Azure subscription ID
- `tenant_id` - Your Azure AD tenant ID
- `sp_client_id` - Service principal client ID
- `sp_client_secret` - Service principal secret
- `pull_secret_path` - Path to your Red Hat pull secret file

### Step 2: Save Your Pull Secret

Save your Red Hat pull secret to a file:
```bash
echo 'your-pull-secret-content' > ~/.aro-pull-secret.txt
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Plan

```bash
terraform plan
```

This shows you what will be created:
- 1 virtual network
- 1 control subnet + N worker subnets
- 1 ARO cluster
- 1 infra machine pool
- N worker machine pools (one per worker subnet)

### Step 5: Deploy

```bash
terraform apply
```

Type `yes` when prompted. The deployment takes about 30-45 minutes.

## Connecting to Your Cluster

After deployment completes, get your cluster credentials:

```bash
# Get the cluster details
az aro list --resource-group <your-rg-name> --output table

# Get the kubeconfig
az aro list-credentials --name <cluster-name> --resource-group <your-rg-name>

# Login to the cluster
oc login <api-server-url> --username kubeadmin --password <password>
```

## Understanding the Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Virtual Network                         │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Control Subnet   │  ← ARO Master Nodes                    │
│  └──────────────────┘                                        │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Worker Subnet 1  │  ← Worker Machine Pool 1               │
│  └──────────────────┘                                        │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Worker Subnet 2  │  ← Worker Machine Pool 2               │
│  └──────────────────┘                                        │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Worker Subnet N  │  ← Worker Machine Pool N               │
│  └──────────────────┘                                        │
│                                                               │
│  ┌──────────────────┐                                        │
│  │ Infra Pool       │  ← Infrastructure Workloads            │
│  └──────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Each worker machine pool runs in its own subnet
- Infra pool handles cluster services (router, registry, monitoring)
- Worker pools handle your application workloads
- Network policies can be applied per subnet for isolation

## Customizing Your Deployment

### Add More Worker Subnets

Edit `terraform.tfvars`:
```hcl
worker_subnet_prefixes = [
  "10.0.2.0/24",
  "10.0.3.0/24",
  "10.0.4.0/24"  # Add more as needed
]
```

Each subnet automatically gets its own worker machine pool.

### Change Node Sizes

```hcl
worker_vm_size = "Standard_D8s_v3"  # Larger workers
infra_vm_size  = "Standard_D4s_v3"  # Smaller infra nodes
```

### Adjust Node Counts

```hcl
worker_node_count = 5   # More workers per pool
infra_node_count  = 2   # HA infra nodes
```

## Environment-Specific Deployments

Use environment-specific variable files:

```bash
# Deploy to dev
terraform apply -var-file="environments/dev/terraform.tfvars"

# Deploy to prod
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## CI/CD with GitHub Actions

This repo includes workflows for automation:

1. **terraform-plan.yml** - Validates and plans on every PR
2. **terraform-apply.yml** - Manual deployment trigger
3. **scheduled-create.yml** - Auto-create dev cluster weekday mornings
4. **scheduled-destroy.yml** - Auto-destroy dev cluster weekday evenings

Set these secrets in your GitHub repository:
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`
- `ARO_PULL_SECRET`

## Remote State (Recommended)

For team collaboration, use remote state:

1. Create an Azure Storage Account for state:
```bash
az group create --name terraform-state-rg --location eastus
az storage account create --name tfstate$RANDOM --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name <storage-account-name>
```

2. Copy `backend.tf.example` to `backend.tf` and fill in your values

3. Initialize with the backend:
```bash
terraform init -backend-config="storage_account_name=<your-storage-account>"
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning:** This will delete your ARO cluster and all data. Make sure you've backed up anything important.

## Troubleshooting

### Issue: Pull secret error
**Solution:** Verify your pull secret file exists and contains valid JSON from Red Hat.

### Issue: Insufficient quota
**Solution:** Request quota increase for Standard_D8s_v3 VMs in your Azure region.

### Issue: Service principal permissions
**Solution:** Ensure your SP has "Contributor" role on the subscription or resource group.

### Issue: Subnet too small
**Solution:** ARO requires /24 or larger subnets. Check your CIDR blocks in `terraform.tfvars`.

## What Gets Created

- **Resource Group:** 1
- **Virtual Network:** 1 with multiple subnets
- **ARO Cluster:** 1 (3 master nodes by default)
- **Machine Pools:** 1 infra + N worker pools
- **Storage Account:** 1 (optional)
- **DNS Zone:** 1 (optional)
- **Front Door:** 1 (optional)

## Cost Estimation

Approximate monthly costs (East US region):
- ARO Cluster (masters): ~$650/month
- Worker nodes (3x D8s_v3): ~$580/month per pool
- Infra nodes (2x D4s_v3): ~$195/month
- Networking: ~$50/month

**Total:** ~$1,475-2,000/month depending on number of worker pools

