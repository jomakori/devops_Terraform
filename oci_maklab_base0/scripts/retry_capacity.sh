#!/bin/bash
# OCI ARM Instance Capacity Retry Script
# This script handles the common "Out of host capacity" error for Free Tier ARM instances
# Usage: ./retry_capacity.sh [max_attempts] [delay_seconds]

set -e

MAX_ATTEMPTS=${1:-30}
DELAY=${2:-60}
ATTEMPT=1

echo "=== OCI ARM Instance Capacity Retry Script ==="
echo "Max attempts: $MAX_ATTEMPTS"
echo "Delay between attempts: ${DELAY}s"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo -e "${YELLOW}Attempt $ATTEMPT of $MAX_ATTEMPTS...${NC}"
    
    # Run terraform apply and capture output
    if doppler run --project devops --config ci -- terraform apply -auto-approve 2>&1 | tee /tmp/tf_output.log; then
        echo -e "${GREEN}✓ Success! Instance created.${NC}"
        exit 0
    fi
    
    # Check if it's a capacity error
    if grep -q "Out of host capacity" /tmp/tf_output.log; then
        echo -e "${RED}✗ Out of host capacity. Retrying in ${DELAY}s...${NC}"
        echo "  Tip: ARM capacity is limited. Try:"
        echo "    - Different availability domain"
        echo "    - Different region (us-phoenix-1, eu-frankfurt-1)"
        echo "    - Smaller instance (1 OCPU, 6GB RAM)"
        echo "    - Off-peak hours (early morning UTC)"
        sleep $DELAY
        ATTEMPT=$((ATTEMPT + 1))
    else
        echo -e "${RED}✗ Non-capacity error. Check logs above.${NC}"
        exit 1
    fi
done

echo -e "${RED}✗ Max attempts reached. Consider:${NC}"
echo "  1. Trying a different region"
echo "  2. Reducing instance size"
echo "  3. Using x86 shape (VM.Standard.E2.1.Micro - Always Free)"
exit 1
