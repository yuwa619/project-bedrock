# Lambda Function

`handler.py` processes S3 `ObjectCreated` events from `bedrock-assets-alt-soe-025-3673`.

Required log format:

```text
Image received: <filename>
```

Verification:

```sh
aws s3 cp test.png s3://bedrock-assets-alt-soe-025-3673/test.png
aws logs tail /aws/lambda/bedrock-asset-processor --region us-east-1 --since 5m
```
