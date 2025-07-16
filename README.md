# Minimal Specification Azure Kubernetes Service (AKS) Cluster

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2FAKS-Minimal-Cluster-Spec%2Fmain%2Farm%2Fazuredeploy.json)

This sample demonstrates how to deploy a truly minimal specification Azure Kubernetes Service (AKS) cluster optimized for cost, learning, and development scenarios.

## 🎯 Overview

This template creates the most minimal AKS cluster possible while maintaining basic functionality:

- **Single node** with smallest available VM size  
- **Free tier control plane** (no management fees)  
- **Basic kubenet networking** (no Azure CNI charges)  
- **Minimal add-ons** (optional monitoring and workload identity)  
- **Cost-optimized settings** throughout  

## 💰 Cost Optimization

- **Estimated monthly cost**: $70-90 USD (VM + storage only)
- **Free control plane**: No management fees
- **Single node**: Minimal compute costs  
- **Basic networking**: No premium networking charges
- **Optional monitoring**: Can be disabled to save costs

## 🚀 Quick Start

### Deploy with Azure CLI

```bash
# Clone the repository
git clone https://github.com/Azure-Samples/minimal-aks-cluster.git
cd minimal-aks-cluster

# Create resource group
az group create --name rg-minimal-aks --location eastus

# Deploy the template
az deployment group create \
  --resource-group rg-minimal-aks \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Deploy with Azure Developer CLI (azd)

```bash
# Clone and initialize
git clone https://github.com/Azure-Samples/minimal-aks-cluster.git
cd minimal-aks-cluster
azd init

# Deploy infrastructure
azd up
```

## ⚙️ Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `clusterName` | `aks-minimal-{uniqueString}` | Name of the AKS cluster |
| `nodeVmSize` | `Standard_D2s_v3` | VM size for cluster nodes |
| `nodeCount` | `1` | Number of nodes (1-3) |
| `enableWorkloadIdentity` | `false` | Enable workload identity |
| `enableMonitoring` | `false` | Enable Log Analytics monitoring |

### Truly Minimal Configuration

For the absolute minimal cluster (lowest cost):

```json
{
  "enableWorkloadIdentity": false,
  "enableMonitoring": false,
  "nodeCount": 1
}
```

## 🧪 Testing the Deployment

After deployment, test your cluster:

```bash
# Get cluster credentials
az aks get-credentials --resource-group rg-minimal-aks --name your-cluster-name

# Verify cluster is running
kubectl get nodes
kubectl get pods --all-namespaces

# Deploy a test application
kubectl create deployment nginx-test --image=nginx:latest
kubectl get pods
```

## 🔒 Security Features

- ✅ **RBAC enabled** by default
- ✅ **Managed identity** for secure authentication  
- ✅ **Optional workload identity** for pod-level security
- ⚠️ **Azure Policy** disabled (enable if compliance required)

## 📊 What's Running

### Always Included (Minimal)

- AKS Control Plane (Free tier)
- Single node with smallest VM
- CoreDNS for name resolution
- Kube-proxy for service networking
- Essential system pods only

### Optionally Included

- Log Analytics workspace (`enableMonitoring: true`)
- Workload Identity webhook (`enableWorkloadIdentity: true`)

### Explicitly Disabled

- Azure Policy/Gatekeeper
- Azure Key Vault Secrets Provider  
- Auto-scaling (can be enabled later)
- Premium networking features

## 🗑️ Cleanup

To avoid ongoing charges:

```bash
# Delete the entire resource group
az group delete --name rg-minimal-aks --yes --no-wait
```

## 📋 Requirements

- Azure CLI 2.60.0 or later
- Contributor access to Azure subscription
- Available quota for Standard_D2s_v3 VMs in your chosen region

## 🤝 Contributing

This project welcomes contributions and suggestions.

## 🏛️ Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

## 📜 License

This project is licensed under the MIT License.

## 🏷️ Tags

`azure` `kubernetes` `aks` `minimal` `cost-optimization` `bicep`
