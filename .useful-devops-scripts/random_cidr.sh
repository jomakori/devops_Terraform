#!/bin/sh
set -e
#   ┌──────────────────────────────────────────────────────────────────────────┐
#   │                           AWS New CIDR Tool                              │
#   │                                                                          │
#   │ This script is used to connect to the AWS, fetch all the existing CIDR   │
#   │ blocks,                                                                  │
#   │ and generate a new CIDR block that is not currently in use.              │
#   │                                                                          │
#   │ Steps to Run:                                                            │
#   │ 1. Ensure you have boto3 installed: `pip install boto3`.                 │
#   │ 2. Make sure your doppler setup is using the devops-ci config            │
#   │ 3. Run the script, pass the env vars via Doppler:                        │
#   │     `doppler run --command='.././acn_token.sh'`                          │
#   └──────────────────────────────────────────────────────────────────────────┘

# List all VPCs and get CIDR blocks
existing_cidrs=$(aws ec2 describe-vpcs --query 'Vpcs[].CidrBlock' --output text --region $DEFAULT_AWS_REGION)

# Generate a random CIDR block that's not currently in use
while true; do
  rand1=$((RANDOM % 256))
  rand2=$((RANDOM % 256))
  random_cidr="10.${rand1}.${rand2}.0/24"

  if [[ ! $existing_cidrs =~ $random_cidr ]]; then
    break
  fi
done

echo "Available CIDR block: $random_cidr"
