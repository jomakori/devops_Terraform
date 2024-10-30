# AWS API Gateway and Domain Cleaner

> **IMPORTANT:** Please use this script responsibly. Deleting API Gateways and domains will permanently remove these resources from your AWS account.

## Overview
`delete_custom_api_domains.sh` is a Bash script utility for managing API Gateways and domains in AWS. API domains are dependencies of API Gateways, hence the need for their removal before deleting API Gateways. The script performs two main tasks:

1. **Lists API Gateways and Domains**: The function `list_api_gateways()` and `list_domains()` retrieve the names and IDs of all API Gateways and domains in a specified region.

2. **Deletes API Gateways and Domains**: The functions `delete_api_gateways()` and `delete_domains()` delete all API Gateways and domains in the specified region.

The script uses the AWS CLI to interact with AWS services.

## Requirements
- AWS CLI installed on your system.
- AWS CLI configured with appropriate AWS credentials.

## How to Run
To run `delete_custom_api_domains.sh`:

```bash
chmod +x delete_custom_api_domains.sh
./delete_custom_api_domains.sh
```

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services. Be aware that this script will permanently delete all API Gateways and domains in the specified region.
