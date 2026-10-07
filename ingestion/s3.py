import boto3

s3 = boto3.client("s3")

def file_exists(bucket, key):
    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True
    
    except Exception as e:
        if e.response['Error']['Code'] == '404':
            return False
        
        raise

def list_csv_files(bucket, folder):
    paginator = s3.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=folder)

    files = []

    for page in pages:
        for obj in page.get("Contents", []):
            file = obj["Key"]

            if file.lower().endswith('.csv'):
                files.append(file)

    return sorted(files)