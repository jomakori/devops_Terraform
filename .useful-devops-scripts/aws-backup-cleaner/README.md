# AWS Backup - Recovery Point Cleaner

> **IMPORTANT:** Please use this script responsibly. Deleting recovery points will permanently remove the ability to restore your AWS resources from those points.


## Overview

The provided Python script is a utility for managing AWS Backup recovery points. AWS Backup is a fully managed backup service that makes it easy to centralize and automate the backup of data across AWS services.

This script does two main things:

1. **Lists Recovery Points**: The function `get_recovery_points(vault_name: str)` retrieves the ARNs (Amazon Resource Names) of all recovery points in a specified backup vault.

2. **Deletes Recovery Points**: The function `delete_recovery_points(vault_name: str, point_arn_list: list)` deletes all recovery points specified by their ARNs in a given backup vault.

The script utilizes the `boto3` Python library to interact with AWS services.

## Requirements

- Python 3.x installed on your system.
- pipx - used to run the script w/ boto3 in an isolated env
- AWS CLI configured with appropriate AWS credentials

## How to Run

To run this script:

```bash
pipx run --spec=boto3 python delete_recovery_points.py <vault-name>
```

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services. Be aware that this script will permanently delete all recovery points in the specified backup vault.
