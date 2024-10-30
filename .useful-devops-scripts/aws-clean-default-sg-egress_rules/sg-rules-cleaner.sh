#!/bin/bash

# Function to get all security groups
get_all_sgs() {
    # Set Variables
    REGION=$1
    SKIP_REGION=$2

    # Ignore null
    if [ "$REGION" == "$SKIP_REGION" ]; then
        continue
    fi

    # Grab SGs
    aws ec2 describe-security-groups --region $REGION --filter "Name=group-name,Values=default" --output text --query 'SecurityGroups[].GroupId'
}

# Function to delete egress rules
delete_rules() {
    # Set Variables
    GROUP_ID=$1
    REGION=$2

    # Delete all egress rules
    delete_egress=$(aws ec2 revoke-security-group-egress --region $REGION --group-id $GROUP_ID --ip-permissions '[{"IpProtocol": "-1", "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]' 2>&1)
    if [ $? -ne 0 ]; then
        echo "❌ Failed to remove egress rule from security group $GROUP_ID in region $REGION."
        echo "$delete_egress" # echo error
        exit 1
    else
        echo "✅ Successfully removed egress rule from security group $GROUP_ID in region $REGION"
    fi

    # Prevent AWS rate-limiting
    sleep 2
}


# Main function
main() {
    # Set Variables
    read -p "Enter the region to skip (↲ for: us-east-2): " SKIP_REGION
    SKIP_REGION=${SKIP_REGION:-us-east-2}

    read -p "Enter the AWS profile to use (↲ for: default): " AWS_PROFILE
    export AWS_PROFILE=${AWS_PROFILE:-default}
    REGIONS=$(aws ec2 describe-regions --output text --query 'Regions[].RegionName')
    ALL_SGS=()

    # Process default SG egress rules across AWS
    echo "Processing default SG egress rules across AWS..."
    for REGION in $REGIONS; do
        SGS=$(get_all_sgs $REGION $SKIP_REGION)
        for SG in $SGS; do
            ALL_SGS+=("$REGION: $SG")
        done
    done

    # Deletion confirmation
    echo "Egress rules from the following security groups will be deleted:"
    for SG in "${ALL_SGS[@]}"; do
        echo $SG
    done
    read -p "Are you sure you want to delete these egress rules? (y/n) " -n 1 -r
    echo    # new line

    # Process rules
    if [[ $REPLY == "y" ]]
    then
        for SG in "${ALL_SGS[@]}"; do
            REGION=${SG%%:*}
            SG=${SG#*:}
            delete_rules $SG $REGION
        done
    else
        echo "Operation skipped."
    fi
}

# Call the main function
main
