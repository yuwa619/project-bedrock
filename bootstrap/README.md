# Bootstrap Backend

This folder creates the S3 bucket used by the main Terraform backend.

```sh
cd bootstrap
terraform init
terraform apply
```

Created bucket:

```text
bedrock-tfstate-alt-soe-025-3673
```

The bucket has versioning, SSE-S3 encryption, ownership controls and public access blocked.

Destroy the bootstrap stack only after the main stack is destroyed and the state bucket is no longer needed.
