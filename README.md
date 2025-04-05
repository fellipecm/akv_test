# Cross-Tenant Azure Key Vault Access Demonstration

This project demonstrates how to access an Azure Key Vault in an enterprise tenant from a Function App in a personal tenant using private network connectivity. It showcases that cross-tenant access to Azure Key Vault is possible when properly configured with virtual network integration and firewall rules.

## Architecture Overview

The setup consists of two parts across different Azure tenants:

1. **Enterprise Tenant:**
   - Azure Key Vault with private endpoint
   - Virtual Network with dedicated subnet
   - Service Principal for Function App access

2. **Personal Tenant:**
   - Azure Function App
   - Virtual Network with dedicated subnet
   - Virtual Network integration for the Function App

The demonstration proves that the Function App in the personal tenant can access the Key Vault in the enterprise tenant when its subnet is allowed in the Key Vault's firewall settings.

## Prerequisites

1. **Azure Subscriptions:**
   - Access to two Azure tenants (Enterprise and Personal)
   - Subscription access in both tenants
   - Appropriate permissions to create resources

2. **Local Tools:**
   - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   - [Terraform](https://www.terraform.io/downloads.html)
   - [Node.js and npm](https://nodejs.org/) (required for Azure Functions Core Tools)
   - [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
   - [Python](https://www.python.org/downloads/) (for Function App development)

3. **Environment Variables:**
   Create a `.env` file in the root directory with the following variables:

   ```bash
   # Enterprise Tenant Settings
   ENT_TENANT_ID="your-enterprise-tenant-id"
   ENT_SUBSCRIPTION_ID="your-enterprise-subscription-id"
   ENT_RESOURCE_GROUP="your-enterprise-resource-group"
   ENT_VNET_NAME="your-enterprise-vnet-name"
   ENT_RESOURCE_GROUP_LOCATION="your-location"
   ENT_AKV_NAME="your-key-vault-name"
   ENT_FUNCTION_APP_SPN_NAME="your-service-principal-name"

   # Personal Tenant Settings
   PER_TENANT_ID="your-personal-tenant-id"
   PER_SUBSCRIPTION_ID="your-personal-subscription-id"
   PER_RESOURCE_GROUP="your-personal-resource-group"
   PER_VNET_NAME="your-personal-vnet-name"
   PER_RESOURCE_GROUP_LOCATION="your-location"
   PER_FUNCTION_APP_NAME="your-function-app-name"
   ```

## Deployment Steps

1. **Clone the Repository:**
   ```bash
   git clone <repository-url>
   cd akv
   ```

2. **Set Up Environment Variables:**
   - Create the `.env` file as described in the prerequisites
   - Source the environment variables:
     ```bash
     source .env
     ```

3. **Run the Setup Script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   The setup script will:
   - Verify required tools are installed
   - Initialize Terraform
   - Deploy infrastructure in both tenants
   - Deploy the Function App code
   - Test the deployment

## Testing the Setup

After deployment, the Function App will attempt to retrieve a secret from the enterprise Key Vault. You can test it manually by calling:

```bash
curl "https://$PER_FUNCTION_APP_NAME.azurewebsites.net/api/getsecret"
```

A successful response indicates that the cross-tenant access is working correctly through the private network connection.

## Security Considerations

This setup demonstrates:
- Private network connectivity between resources in different tenants
- Controlled access to Azure Key Vault using network restrictions
- Service Principal authentication for cross-tenant access
- Virtual Network integration for secure communication

Note: Ensure that you follow your organization's security policies when implementing cross-tenant access patterns.