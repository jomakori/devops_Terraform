## AWS EBS Volume Cleaner 

> **IMPORTANT:** Please use this script responsibly. Deleting EBS volumes will permanently remove the data stored in those volumes.

## Overview

The provided Python script is a utility for managing AWS EBS volumes. Amazon Elastic Block Store (EBS) is an easy to use, high-performance, block-storage service designed for use with Amazon Elastic Compute Cloud (EC2) for both throughput and transaction intensive workloads at any scale.

This script does two main things:

1. **Lists EBS Volumes**: The script retrieves all the EBS volumes available in the specified region under the provided AWS profile.

2. **Deletes Unattached EBS Volumes**: The script checks for any EBS volumes which are not currently attached to any EC2 instances. These volumes are then deleted.

The script utilizes the `boto3` Python library to interact with AWS services.

## Requirements

- Python 3.x installed on your system.
- pipx - used to run the script w/ boto3 in an isolated env
- AWS CLI configured with appropriate AWS credentials

## How to Run

To run this script:

```bash
pipx run --spec=boto3 python ebs-cleaner.py
```

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services. Be aware that this script will permanently delete all unattached EBS volumes in the specified region under the provided AWS profile.
