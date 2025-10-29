import os
import json
import datetime
import base64
import logging
import uuid

import azure.functions as func
from azure.identity import DefaultAzureCredential, ClientSecretCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, SignatureAlgorithm
from azure.storage.blob import BlobServiceClient, ContentSettings

# environment variables
KEY_VAULT_NAME = os.getenv('KEY_VAULT_NAME')
SIGNING_KEY_NAME = os.getenv('SIGNING_KEY_NAME', 'evidence-signing-key')
EVIDENCE_STORAGE_ACCOUNT = os.getenv('EVIDENCE_STORAGE_ACCOUNT')
# When running in Azure, DefaultAzureCredential will pick up the managed identity
credential = DefaultAzureCredential()

def create_evidence(payload: dict) -> dict:
    evidence = {
        "evidence_id": f"EV-{datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}-{str(uuid.uuid4())[:8]}",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "payload": payload
    }
    return evidence

def sign_with_keyvault(evidence_json: str) -> dict:
    key_vault_url = f"https://{KEY_VAULT_NAME}.vault.azure.net"
    key_client = KeyClient(vault_url=key_vault_url, credential=credential)
    key = key_client.get_key(SIGNING_KEY_NAME)
    crypto = CryptographyClient(key, credential=credential)
    # sign the SHA256 digest
    digest = __hash_bytes(evidence_json.encode('utf-8'))
    sign_result = crypto.sign(SignatureAlgorithm.rs256, digest)
    signature_b64 = base64.b64encode(sign_result.signature).decode('utf-8')
    return {"signature": signature_b64, "keyid": key.id}

def __hash_bytes(b: bytes):
    import hashlib
    h = hashlib.sha256()
    h.update(b)
    return h.digest()

def upload_to_blob(evidence_json: str, signature: dict, blob_name: str):
    # Use connection via DefaultAzureCredential with blob service client (requires Azure AD auth)
    blob_service_client = BlobServiceClient(
        account_url=f"https://{EVIDENCE_STORAGE_ACCOUNT}.blob.core.windows.net",
        credential=credential
    )
    container_name = "evidence"
    try:
        container_client = blob_service_client.get_container_client(container_name)
        # create container if not exists
        container_client.create_container()
    except Exception:
        # container likely exists
        pass

    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    metadata = {
        "keyid": signature.get("keyid", ""),
        "signed": "true"
    }
    content_settings = ContentSettings(content_type='application/json')
    combined = {
        "evidence": json.loads(evidence_json),
        "signature": signature.get("signature")
    }
    blob_client.upload_blob(json.dumps(combined), overwrite=True, metadata=metadata, content_settings=content_settings)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Evidence function triggered.')
    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON", status_code=400)

    # Build evidence
    evidence = create_evidence(req_body)
    evidence_json = json.dumps(evidence, indent=2, sort_keys=True)

    # Sign with Key Vault key
    signature = sign_with_keyvault(evidence_json)

    # Upload to blob
    blob_name = f"{evidence['evidence_id']}.json"
    upload_to_blob(evidence_json, signature, blob_name)

    response = {
        "evidence_id": evidence["evidence_id"],
        "blob": f"https://{EVIDENCE_STORAGE_ACCOUNT}.blob.core.windows.net/evidence/{blob_name}",
        "signed_by": signature.get("keyid")
    }
    return func.HttpResponse(json.dumps(response), status_code=200, mimetype="application/json")

