## AWS Security Group Egress Rules Cleaner 

> **IMPORTANT:** Please use this script responsibly. Deleting egress rules may affect the communication of associated instances with other networks.

## Overview

This shell script is used for managing AWS Security Group Egress Rules for Default SGs. Amazon Security Groups act as a virtual firewall for your instance to control inbound and outbound traffic.

This script does two main things:

1. **Lists Security Groups**: The script retrieves all the default security groups (outside default region). The egress rules are grabbed and recorded.

2. **Deletes Egress Rules**: The script checks for any egress rules associated with each default security group (outside default region). These rules are then deleted. Since in most cases, other regions aren't being used.

The script utilizes the `aws cli` to interact with AWS services.

## Requirements

- Bash shell environment on your system.
- AWS CLI installed and configured with appropriate AWS credentials

## How to Run

To run this script:

```bash
./sg-rules-cleaner.sh
```

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services. Be aware that this script will permanently delete all egress rules of the specified security groups in the specified region under the provided AWS profile. 

## User Prompts

After running the script, you will be prompted to enter:

- The region you want to skip. If you don't want to skip any region, just press Enter.
- The AWS profile to use. If you want to use the default profile, just press Enter.

After this, the script will list all the security groups from which the egress rules will be deleted. You will be asked to confirm if you want to delete these egress rules.

Please use this script responsibly as deleting egress rules can affect the communication of your instances with other networks.
