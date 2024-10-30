# AWS S3 Bucket Cleanup - By Keyword

> **IMPORTANT:** Please use this script responsibly. Deleting S3 buckets will permanently remove all the data stored in those buckets. 

## Overview

This python script allows us to mass delete S3 buckets by the keywords fed into the program.

This script does two main things:

1. **Lists Buckets**: The function `get_buckets_to_delete(keywords: list)` retrieves all the S3 buckets whose names match the specified keywords.

2. **Deletes Buckets**: If user confirms changes, the function `delete_buckets(buckets: list)` deletes all the specified S3 buckets. It also utilizes `delete_all_objects` function to remove all object prior to bucket deletion

The script utilizes the `boto3` Python library to interact with AWS services.

## Requirements

- Python 3.x installed on your system.
- pipx - used to run the script w/ boto3 in an isolated environment
- AWS CLI configured with appropriate AWS credentials

## How to Run

To run this script:

```bash
pipx run --spec=boto3 python s3-bucket-cleaner.py
```

The script will first prompt you to enter your AWS profile name, region, and the keywords to match the bucket names. By default, it uses the default profile and the 'us-east-2' region.

Next, it will list all the buckets that match the keywords and ask for your confirmation before deleting them.

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services. Be aware that this script will permanently delete all the specified S3 buckets, and it's not possible to recover them once deleted.
