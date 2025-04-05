import azure.functions as func
import logging
import os

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


app = func.FunctionApp()

@app.function_name(name="GetSecret")
@app.route(route="getsecret", auth_level=func.AuthLevel.ANONYMOUS)  # Temporarily set to anonymous for testing
def get_secret(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Get Key Vault details from environment variables
        key_vault_name = os.environ["KEY_VAULT_NAME"]
        key_vault_uri = f"https://{key_vault_name}.vault.azure.net"

        # Create a SecretClient using default credentials
        credential = DefaultAzureCredential()
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)

        # Get the secret
        secret_name = "example-secret"  # This matches the secret we created in Terraform
        secret = secret_client.get_secret(secret_name)

        return func.HttpResponse(
            f"Secret value: {secret.value}",
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(
            f"Error accessing Key Vault: {str(e)}",
            status_code=500
        )