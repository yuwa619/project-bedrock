from urllib.parse import unquote_plus


def handler(event, context):
    for record in event.get("Records", []):
        key = record.get("s3", {}).get("object", {}).get("key", "")
        filename = unquote_plus(key)
        print(f"Image received: {filename}")

    return {"statusCode": 200}
