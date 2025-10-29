# Loi 09-08 Azure Compliance - Demo Repo

This repository provides an end-to-end demo to **automate Azure compliance for Morocco's Loi n°09-08** using:
- Azure Policy (custom policies + Initiative)
- Azure Bicep for infrastructure (Function App, Storage, Key Vault, Managed Identity, Log Analytics)
- Azure Function (Python) to create signed evidence artifacts and store them in immutable storage
- GitHub Actions CI/CD to deploy infra and register policies

## Quickmap (what files do)
- `/policies` : custom Azure Policy definitions + Initiative (policy set).
- `/bicep/main.bicep` : Infrastructure as Code to deploy the demo environment.
- `/functions/evidence-function` : Azure Function (Python) that creates signed evidence JSON and uploads to blob storage.
- `/.github/workflows/ci-cd.yml` : GitHub Actions workflow that deploys Bicep, policies, and the function.

## Prerequisites (what you need)
1. Azure subscription with Owner or Policy Contributor & Resource Group Contributor rights.
2. Azure CLI installed locally (az).
3. A Service Principal for GitHub Actions (or use OIDC; below uses service principal secret).
4. GitHub repo created and secrets added (see GitHub Actions section in README).

## How to deploy (local quickstart)
1. Clone this repo locally.
2. Edit `bicep/main.bicep` if you want to change resource names/locations.
3. Login and create a resource group:

