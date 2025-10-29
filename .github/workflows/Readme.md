This workflow does:

Checkout code.

    1-Login to Azure (service principal via secrets).

    2-Deploy Bicep to a specified resource group.

    3-Upload policy definitions to subscription.

    4-Create initiative and assign it (you will need to set SUBSCRIPTION_ID).

    5-Deploy Function by packaging the function and using azure/functions-action or azure CLI zip deploy.
