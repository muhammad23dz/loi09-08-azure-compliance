#  Deployment Guide LOI 09-08 Azure Compliance Automation

This guide explains **exactly what to do after cloning** this repository to deploy the full Azure compliance automation solution for **Morocco’s Loi n°09-08** (data protection law).

---

##  Prerequisites

Before you start, make sure the following are already set up:

 Active **Azure subscription** and Resource Group  
 **Azure CLI** installed and logged in (`az login`)  
 Permissions: **Contributor** or **Owner** + **Policy Contributor**  
 **GitHub repository** linked to this code  
 **GitHub Actions secrets** configured:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

---

##  Step-by-Step Deployment

### 1 Clone the repository

```bash
git clone https://github.com/<your-org>/loi09-08-azure-compliance.git
cd loi09-08-azure-compliance
````

Review the structure:

```
/bicep                → Infrastructure as Code  
/policies             → Azure Policy definitions  
/functions            → Azure Function (Python)  
/.github/workflows    → CI/CD automation  
/docs                 → Documentation & controls matrix
```

---

### 2️ Create the Resource Group (if not already)

```bash
az group create -n loi09-rg -l northeurope
```

You can change the name or region — just ensure it matches what’s referenced in your workflow file (`ci-cd.yml`).

---

### 3️ Deploy infrastructure (Bicep)

```bash
az deployment group create \
  --name mainDeployment \
  --resource-group loi09-rg \
  --template-file bicep/main.bicep
```

This deploys:

* Evidence Storage Account
* Function App + Hosting Plan
* Key Vault (for signing key)
* Managed Identity
* Log Analytics workspace

After deployment, note the **outputs** — you’ll need:

```
functionAppName
evidenceStorageAccount
keyVaultName
managedIdentityClientId
```

---

### 4️ Create the signing key in Key Vault

```bash
az keyvault key create \
  --vault-name <keyVaultName> \
  --name evidence-signing-key \
  --kty RSA \
  --size 2048
```

This key is used by the Azure Function to **sign evidence JSONs cryptographically**.

---

### 5️ Create the “evidence” blob container

```bash
az storage container create \
  --account-name <evidenceStorageAccount> \
  --name evidence \
  --auth-mode login
```

Optional (recommended for real deployments):

```bash
az storage container immutability-policy create \
  --account-name <evidenceStorageAccount> \
  --container-name evidence \
  --period 90
```

This enables **immutable retention** of evidence for 90 days.

---

### 6️ Deploy all Azure Policies

```bash
az policy definition create --name require-storage-encryption --rules policies/policy-storage-encryption.json --mode Indexed
az policy definition create --name require-secure-transfer --rules policies/policy-storage-secure-transfer.json --mode Indexed
az policy definition create --name require-diagnostics --rules policies/policy-diagnostics-enabled.json --mode Indexed
az policy definition create --name require-data-class-tag --rules policies/policy-require-data-class-tag.json --mode Indexed
az policy definition create --name allowed-locations-pii --rules policies/policy-allowed-locations.json --mode Indexed

az policy set-definition create \
  --name loi09-08-initiative \
  --definitions policies/initiative-loi09-08.json \
  --display-name "LOI09-08 Initiative"

az policy assignment create \
  --name loi09-08-assignment \
  --policy loi09-08-initiative \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

These policies enforce:

* Storage encryption at rest
* HTTPS-only connections
* Diagnostic settings for audit trails
* Mandatory `data_class` tagging
* Region restrictions for PII resources

---

### 7️ Deploy the Azure Function (choose one method)

####  Option A — Manual (local)

```bash
cd functions/evidence-function
zip -r function.zip .
FUNCNAME=$(az deployment group show -g loi09-rg --name mainDeployment --query properties.outputs.functionAppName.value -o tsv)
az webapp deployment source config-zip -g loi09-rg -n $FUNCNAME --src function.zip
```

####  Option B CI/CD via GitHub Actions

Just push your code to the `main` branch:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will:

1. Authenticate to Azure.
2. Deploy the infrastructure (Bicep).
3. Register and assign policies.
4. Deploy the Function automatically.

Check progress under your repo → **Actions** tab.

---

### 8️ Configure the Function App

In Azure Portal → Function App → **Configuration**, verify:

| Setting                    | Value                      |
| -------------------------- | -------------------------- |
| `EVIDENCE_STORAGE_ACCOUNT` | `<evidenceStorageAccount>` |
| `KEY_VAULT_NAME`           | `<keyVaultName>`           |
| `SIGNING_KEY_NAME`         | `evidence-signing-key`     |
| `FUNCTIONS_WORKER_RUNTIME` | `python`                   |

Also confirm that the **Managed Identity** assigned to the Function has access to the Key Vault (permissions: `sign`, `get`).

---

### 9️ Test the Function (create sample evidence)

Get your Function URL and key (Azure Portal → Function → Get Function URL).

Then run:

```bash
curl -X POST "<FUNCTION_URL>?code=<FUNCTION_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
        "policy": "require-storage-encryption",
        "resource": "/subscriptions/.../resourceGroups/demo-rg/providers/Microsoft.Storage/storageAccounts/demo",
        "status": "remediated",
        "notes": "Applied encryption and diagnostics"
      }'
```

 Response example:

```json
{
  "evidence_id": "EV-20251029T103500Z-1a2b3c4d",
  "blob": "https://loievidence.blob.core.windows.net/evidence/EV-20251029T103500Z-1a2b3c4d.json",
  "signed_by": "https://loikv.vault.azure.net/keys/evidence-signing-key/<version>"
}
```

Now check your **evidence container** — a signed JSON file should appear.

---

###  10 Verify Compliance in Azure Portal

Go to **Azure Portal → Policy → Assignments → LOI09-08 Initiative → Compliance**.
You’ll see compliance status for all resources.
When you fix noncompliant ones, you can generate new evidence records through the Function.

---

##  Recap

| Component                   | Purpose                                    |
| --------------------------- | ------------------------------------------ |
| **Azure Policies**          | Enforce Loi 09-08 data protection controls |
| **Bicep IaC**               | Reproducible environment deployment        |
| **Azure Function (Python)** | Generates and signs compliance evidence    |
| **Key Vault**               | Holds secure signing keys                  |
| **GitHub Actions**          | CI/CD for full automation                  |

---

##  Optional Enhancements

* Enable **Key Vault purge protection** and RBAC mode
* Connect **Microsoft Defender for Cloud** for posture management
* Add **Sentinel analytics rules** for incident automation
* Build a small **dashboard** (Power BI or Static Web App) to visualize compliance and evidence

---

##  You’re Done

You’ve successfully deployed the **LOI 09-08 Azure Compliance Automation** solution.



* Continuous compliance evaluation
* Automatic evidence generation with cryptographic signatures
* A full CI/CD pipeline to redeploy and scale this system

 


