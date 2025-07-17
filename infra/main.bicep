// Minimal Spec AKS Cluster - Main Bicep Template
// This template creates a cost-optimized AKS cluster with minimal specifications
// while maintaining essential security and functionality standards.

targetScope = 'resourceGroup'

// Parameters for customization
@description('Unique name for the AKS cluster')
@minLength(3)
@maxLength(63)
param clusterName string = 'aks-minimal-${uniqueString(resourceGroup().id)}'

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('DNS prefix for the AKS cluster')
param dnsPrefix string = clusterName

@description('Kubernetes version for the cluster - leave empty for default')
param kubernetesVersion string = ''

@description('VM size for the default node pool (minimal spec: Standard_B2s)')
@allowed([
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D2s_v4'
  'Standard_E2as_v4'
])
param nodeVmSize string = 'Standard_B2s'

@description('Number of nodes in the default pool (minimal: 1)')
@minValue(1)
@maxValue(3)
param nodeCount int = 1

@description('Environment tag for resource organization')
@allowed([
  'dev'
  'test'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Environment name for AZD integration')
param environmentName string = environment

@description('Enable workload identity (adds webhook overhead but provides secure pod identity)')
param enableWorkloadIdentity bool = false

@description('Enable monitoring with Log Analytics (adds cost but provides observability)')
param enableMonitoring bool = false

@description('OS disk type: Ephemeral (cheaper, faster) or Managed (persistent)')
@allowed([
  'Ephemeral'
  'Managed'
])
param osDiskType string = 'Ephemeral'

@description('OS disk size in GB for managed disks (ignored for ephemeral)')
@minValue(30)
@maxValue(2048)
param osDiskSizeGB int = 30

// Variables for resource configuration
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var tags = {
  environment: environment
  'azd-env-name': environment
  purpose: 'minimal-aks-cluster'
  costOptimized: 'true'
  createdBy: 'bicep-template'
}

// User-assigned managed identity for AKS cluster
resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${clusterName}-${resourceToken}'
  location: location
  tags: tags
}

// AKS Cluster with minimal specifications
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksIdentity.id}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: 'Free' // Free tier for cost optimization
  }
  properties: {
    kubernetesVersion: empty(kubernetesVersion) ? null : kubernetesVersion
    dnsPrefix: dnsPrefix
    enableRBAC: true
    
    // Agent pool configuration - minimal spec
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        mode: 'System'
        count: nodeCount
        vmSize: nodeVmSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        osDiskType: osDiskType
        
        // OS Disk Size Configuration:
        // - Ephemeral disks: Set to 0. This instructs Azure to automatically size the disk based on the VM's cache capacity,
        //   which is determined by the VM size. This configuration optimizes for faster I/O and cost savings. Note that data is lost on VM restart.
        // - Managed disks: Use the configurable osDiskSizeGB parameter (30-2048 GB) for persistent storage.
        osDiskSizeGB: osDiskType == 'Ephemeral' ? 0 : osDiskSizeGB
        
        maxPods: 30 // Reduced for minimal spec
        enableAutoScaling: false // Disabled for cost control
        enableNodePublicIP: false
        enableEncryptionAtHost: false // Disabled for cost optimization
        enableUltraSSD: false
      }
    ]
    
    // Network configuration - basic kubenet for cost efficiency
    networkProfile: {
      networkPlugin: 'kubenet'
      loadBalancerSku: 'standard'
      networkPolicy: 'none' // Simplified for minimal spec
      podCidr: '10.244.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    
    // Truly minimal add-ons configuration - only enable what's absolutely necessary
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: false // Disabled for minimal spec
      }
      azurepolicy: {
        enabled: false // Explicitly disabled for minimal spec
        config: null
      }
      httpApplicationRouting: {
        enabled: false // Deprecated and disabled
      }
      omsagent: {
        enabled: enableMonitoring // Conditionally enable monitoring
        config: enableMonitoring ? {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        } : null
      }
    }
    
    // Security profile with conditional workload identity
    securityProfile: enableWorkloadIdentity ? {
      workloadIdentity: {
        enabled: true // Enable for secure pod identity
      }
    } : {}
    
    // API server access profile
    apiServerAccessProfile: {
      enablePrivateCluster: false // Public for simplicity in minimal spec
      authorizedIPRanges: [] // Open access for minimal spec
    }
    
    // Auto-upgrade configuration
    autoUpgradeProfile: {
      upgradeChannel: 'patch' // Patch-level auto-upgrades only
      nodeOSUpgradeChannel: 'NodeImage'
    }
    
    // OIDC Issuer for workload identity (only if workload identity is enabled)
    oidcIssuerProfile: enableWorkloadIdentity ? {
      enabled: true
    } : {
      enabled: false
    }
    
    // Disable features not needed for minimal spec
    disableLocalAccounts: false // Keep local accounts for simplicity
    enablePodSecurityPolicy: false // Deprecated
    
    // Storage profile with minimal configuration
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: false // Disabled for cost optimization
      }
      snapshotController: {
        enabled: false // Disabled for minimal spec
      }
    }
  }
}

// Optional: Log Analytics Workspace for monitoring (only created if monitoring is enabled)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (enableMonitoring) {
  name: 'log-${take(clusterName, 20)}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018' // Standard pricing tier
    }
    retentionInDays: 30 // Minimal retention for cost control
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Note: ACR role assignment removed to work with Contributor-level permissions
// If you need ACR integration, request User Access Administrator role or create the role assignment manually:
// az role assignment create --assignee <managed-identity-principal-id> --role AcrPull --scope <acr-resource-id>

// Outputs for downstream usage
@description('The resource ID of the AKS cluster')
output aksClusterId string = aksCluster.id

@description('The name of the AKS cluster')
output aksClusterName string = aksCluster.name

@description('The FQDN of the AKS cluster')
output aksClusterFqdn string = aksCluster.properties.fqdn

@description('The API server endpoint URL')
output aksApiServerUrl string = aksCluster.properties.fqdn

@description('The managed identity resource ID')
output managedIdentityId string = aksIdentity.id

// Commented out since Log Analytics is conditional for truly minimal spec
// @description('The Log Analytics workspace ID')
// output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('The Log Analytics workspace ID (only available if monitoring is enabled)')
output logAnalyticsWorkspaceId string = enableMonitoring ? logAnalyticsWorkspace.id : ''

@description('Azure portal URL for the AKS cluster')
output portalUrl string = 'https://portal.azure.com/#resource${aksCluster.id}/overview'

@description('The resource group ID')
output RESOURCE_GROUP_ID string = resourceGroup().id

@description('Connection commands for kubectl')
output kubectlConnectCommand string = 'az aks get-credentials --resource-group ${resourceGroup().name} --name ${aksCluster.name}'
