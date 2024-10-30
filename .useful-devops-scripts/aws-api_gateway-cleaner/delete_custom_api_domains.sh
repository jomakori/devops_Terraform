#!/bin/bash

# Default values
REGION='us-east-2'
AWS_PROFILE='default'

# Grab list of API Gateways & domains
list_domains() {
    echo "Listing all domain names in $REGION..."
    export domain_names=$(aws apigateway get-domain-names --region $REGION --profile $AWS_PROFILE --output text --query 'items[*].[domainName]' 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$domain_names"
    else
        echo "There are no API Domain names present in $REGION."
    fi
}
list_api_gateways() {
    echo "Listing all API Gateways in $REGION..."
    # API Gateway names array
    api_gateways=$(aws apigateway get-rest-apis --region $REGION --profile $AWS_PROFILE --output text --query 'items[*].[name]' 2>/dev/null)
    IFS=$'\n' read -rd '' -a api_gateways_array <<<"$api_gateways"
    # API Gateway IDs array (for deletion operation)
    api_gateways_ids=$(aws apigateway get-rest-apis --region $REGION --profile $AWS_PROFILE --output text --query 'items[*].[id]' 2>/dev/null)
    IFS=$'\n' read -rd '' -a api_gateways_ids_array <<<"$api_gateways_ids"

    if [ -z "$api_gateways" ]; then
        echo "There are no API Gateways present in $REGION."
    else
        # List all the items
        echo "$api_gateways"
    fi
}

# Function to delete the domains
delete_domains() {
    for domain in $domain_names
    do
        echo "" # seperator
        echo "Deleting domain: $domain"
        
        # Assign the result of the AWS command to the variable 'result'
        result=$(aws apigateway delete-domain-name --region $REGION --profile $AWS_PROFILE --domain-name $domain 2>&1)
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "✅ Successfully deleted domain: $domain"
        else
            echo "❌ Failed to delete domain: $domain"
            echo "Error: $result"
        fi

        # Avoid rate limiting - 30 second wait period
        ## Reason: https://repost.aws/knowledge-center/api-gateway-delete-domain-name
        counter=0
        total_time=30
        while [ $counter -lt $total_time ]
            do
                counter=$((counter+1))
                echo -ne "Pause time: $counter/$total_time seconds\r"
                sleep 1
            done
        echo
    done
}
delete_api_gateways() {
    # Get Array length
    length=${#api_gateways_array[@]}

    # Process list
    for ((i=0; i<$length; i++))
    do
        echo "" # seperator
        echo "Deleting API Gateway: ${api_gateways_array[$i]} - ID ${api_gateways_ids_array[$i]}"

        # Perform deletion
        result=$(aws apigateway delete-rest-api --region $REGION --profile $AWS_PROFILE --rest-api-id ${api_gateways_ids_array[$i]} 2>&1)
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "✅ Successfully deleted API Gateway: ${api_gateways_array[$i]}"
        else
            echo "❌ Failed to delete API Gateway: ${api_gateways_array[$i]}"
            echo "Error: $result"
        fi

        # Avoid rate limiting - 30 second wait period
        ## Reason: https://repost.aws/knowledge-center/api-gateway-delete-domain-name
        counter=0
        total_time=30
        while [ $counter -lt $total_time ]
            do
                counter=$((counter+1))
                echo -ne "Pause time: $counter/$total_time seconds\r"
                sleep 1
            done
        echo
    done
}

# Main function
main() {
    # Grab AWS credentials
    echo -n "Enter AWS Profile [default]: "
    read profile
    if [ -z "$profile" ]; then
        AWS_PROFILE=$AWS_PROFILE
    else
        AWS_PROFILE=$profile
    fi

    echo -n "Enter AWS Region [us-east-2]: "
    read region
    if [ -z "$region" ]; then
        REGION=$REGION
    else
        REGION=$region
    fi

    # Confirm deletion of API custom domains & API Gateways
    list_domains
    echo -n "Do you want to delete all domains? [y/n]: "
    read delete_domains_confirmation
    list_api_gateways
    echo -n "Do you want to delete all API Gateways? [y/n]: "
    read delete_api_gateways_confirmation

    # Perform Operations
    if [ "$delete_domains_confirmation" == "y" ]; then
        delete_domains
    else
        echo "Delete Domains operation skipped."
    fi
    
    if [ "$delete_api_gateways_confirmation" == "y" ]; then
        delete_api_gateways
    else
        echo "Delete API Gateways operation skipped."
    fi
}

# Call the main function
main
