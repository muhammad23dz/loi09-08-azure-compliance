# Controls Matrix (sample)

| Legal requirement (Loi 09-08) | Technical control | Azure implementation |
|---|---:|---|
| Security of personal data (confidentiality at rest) | Encryption at rest | Azure Policy: require storage encryption (policy-storage-encryption.json) |
| Encryption in transit | Secure transfer (HTTPS) | Azure Policy: require storage supportsHttpsTrafficOnly true |
| Logging / audit trails | Diagnostics enabled & central logging | Azure Policy: require diagnostic settings; Log Analytics workspace + Sentinel |
| Data classification / inventory | Tagging & data inventory | Azure Policy: require `data_class` tag; use resource graph for inventory |
| Cross-border transfer controls | Region restrictions | Azure Policy: allowed locations for resources tagged `PII` |
| Evidence & accountability | Signed, immutable evidence stored off main resource | Azure Function creates signed JSON stored in evidence container in Storage Account; Key Vault for signing key |
