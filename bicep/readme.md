This content  deploys:

    -Resource group scoped deployment (you will run in a resource group).

    -Storage Account for evidence (with immutability policy placeholder).

    -Key Vault (for signing key).

    -User-assigned Managed Identity for automation.

    -Function App on Consumption Plan with a dedicated storage account.

    -Log Analytics workspace.

Notes / Next steps after Bicep deployment

    After deployment, add a container named evidence in the evidence storage account and set access policy to restrict writes to the managed identity (this script does not set blob-level ACLs because those require additional steps).

    In production, enable immutable blob storage / legal hold for the evidence container (additional commands / Storage account configuration).
