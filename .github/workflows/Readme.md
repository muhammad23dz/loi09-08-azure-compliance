This workflow does:

Checkout code.

    1-Login to Azure (service principal via secrets).

    2-Deploy Bicep to a specified resource group.

    3-Upload policy definitions to subscription.

    4-Create initiative and assign it (you will need to set SUBSCRIPTION_ID).

    5-Deploy Function by packaging the function and using azure/functions-action or azure CLI zip deploy.
Important notes:

    The az deployment group create in the Bicep step produces outputs — the workflow assumes the deployment name mainDeployment. If the Bicep deployment is named differently, modify accordingly. Simpler: run az deployment group create -g $RG -f bicep/main.bicep --name mainDeployment to produce the expected output. You can update the Bicep step in the workflow to add --name mainDeployment.

    The Actions job expects the GitHub repo secrets: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID. Add them in the repo settings
