#!/bin/bash

# Load environment variables
source .env

# Function to display usage
show_usage() {
    echo "Usage: $0 [-c|--create] [-d|--destroy] [-h|--help]"
    echo "Options:"
    echo "  -c, --create    Create new infrastructure and deploy Function App"
    echo "  -d, --destroy   Destroy all infrastructure"
    echo "  -h, --help      Display this help message"
    exit 1
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_usage
fi

ACTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--create)
            ACTION="create"
            shift
            ;;
        -d|--destroy)
            ACTION="destroy"
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Install Terraform..."
    exit 1
fi

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Check if Azure Functions Core Tools is installed
if ! command -v func &> /dev/null; then
    echo "Installing Azure Functions Core Tools..."
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        echo "Please install Node.js and npm first from: https://nodejs.org/"
        exit 1
    fi
    npm install -g azure-functions-core-tools@4 --unsafe-perm true
fi

# Login to Enterprise subscription
az account set --subscription $ENT_SUBSCRIPTION_ID

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Handle different actions
case $ACTION in
    "create")
        # Deploy infrastructure
        echo "Deploying infrastructure..."
        terraform apply -auto-approve \
          -var "ent_tenant_id=$ENT_TENANT_ID" \
          -var "ent_subscription_id=$ENT_SUBSCRIPTION_ID" \
          -var "ent_resource_group=$ENT_RESOURCE_GROUP" \
          -var "ent_vnet_name=$ENT_VNET_NAME" \
          -var "ent_resource_group_location=$ENT_RESOURCE_GROUP_LOCATION" \
          -var "ent_akv_name=$ENT_AKV_NAME" \
          -var "ent_function_app_spn_name=$ENT_FUNCTION_APP_SPN_NAME" \
          -var "per_tenant_id=$PER_TENANT_ID" \
          -var "per_subscription_id=$PER_SUBSCRIPTION_ID" \
          -var "per_resource_group=$PER_RESOURCE_GROUP" \
          -var "per_vnet_name=$PER_VNET_NAME" \
          -var "per_resource_group_location=$PER_RESOURCE_GROUP_LOCATION" \
          -var "per_function_app_name=$PER_FUNCTION_APP_NAME"

        # Deploy Function App code
        echo "Deploying Function App code..."
        az account set --subscription $PER_SUBSCRIPTION_ID
        cd function_app
        func azure functionapp publish $PER_FUNCTION_APP_NAME --python
        cd ..

        echo "Waiting for Function App to be ready..."
        # Wait for the Function App to be ready
        sleep 30

        echo "Testing function app endpoint..."
        curl "https://$PER_FUNCTION_APP_NAME.azurewebsites.net/api/getsecret"
        ;;
    "destroy")
        echo "Warning: This will destroy all infrastructure. Are you sure? (y/N)"
        read -r confirmation
        if [[ $confirmation =~ ^[Yy]$ ]]; then
            echo "Destroying infrastructure..."
            terraform destroy -auto-approve \
              -var "ent_tenant_id=$ENT_TENANT_ID" \
              -var "ent_subscription_id=$ENT_SUBSCRIPTION_ID" \
              -var "ent_resource_group=$ENT_RESOURCE_GROUP" \
              -var "ent_vnet_name=$ENT_VNET_NAME" \
              -var "ent_resource_group_location=$ENT_RESOURCE_GROUP_LOCATION" \
              -var "ent_akv_name=$ENT_AKV_NAME" \
              -var "ent_function_app_spn_name=$ENT_FUNCTION_APP_SPN_NAME" \
              -var "per_tenant_id=$PER_TENANT_ID" \
              -var "per_subscription_id=$PER_SUBSCRIPTION_ID" \
              -var "per_resource_group=$PER_RESOURCE_GROUP" \
              -var "per_vnet_name=$PER_VNET_NAME" \
              -var "per_resource_group_location=$PER_RESOURCE_GROUP_LOCATION" \
              -var "per_function_app_name=$PER_FUNCTION_APP_NAME"
            echo "Infrastructure destroyed successfully!"
        else
            echo "Destroy operation cancelled."
        fi
        ;;
    *)
        show_usage
        ;;
esac

echo "Operation complete!"
