#!/bin/bash
set -e

# Script to generate Atmos configuration at runtime
# Usage: ./generate-atmos-config.sh <workspace-name>
# 
# This script creates the Atmos configuration structure that wraps existing Terraform workspaces
# It dynamically detects required variables from each workspace's variables.tf file
# Configuration is generated at repository root in the stacks/ directory

WORKSPACE="${1:?Workspace name required}"

# Validate workspace exists
if [ ! -d "$WORKSPACE" ]; then
    echo "Error: Workspace directory not found: $WORKSPACE"
    exit 1
fi

# Extract required variables from workspace's variables.tf
extract_variables() {
    local workspace_dir="$1"
    local vars_file="${workspace_dir}/variables.tf"
    
    if [ ! -f "$vars_file" ]; then
        echo "Error: variables.tf not found in $workspace_dir"
        exit 1
    fi
    
    # Extract variable names (lines with 'variable "...')
    grep -oP 'variable "\K[^"]+' "$vars_file" || true
}

# Get all variables from the workspace
VARIABLES=$(extract_variables "$WORKSPACE")

# Create Atmos root configuration (if it doesn't exist)
if [ ! -f "atmos.yaml" ]; then
    cat > atmos.yaml << 'EOF'
# Atmos Configuration
# Reference: https://atmos.tools/cli/configuration

base_path: "."

components:
  terraform:
    base_path: "stacks"
    apply_auto_approve: false
    deploy_run_init: true
    init_run_terraform_fmt_check: false
    auto_generate_backend_file: false

stacks:
  base_path: "stacks"
  included_paths:
    - "**/*.yaml"
  excluded_paths:
    - "**/_*.yaml"

logs:
  level: "info"

cli:
  interactive: false
  colors: true
EOF
    echo "✅ Created atmos.yaml"
fi

# Create stacks directory
mkdir -p stacks

# Generate stack configuration for the workspace
STACK_NAME=$(echo "$WORKSPACE" | tr '/' '-')

cat > "stacks/${STACK_NAME}.yaml" << EOF
# Stack configuration for workspace: $WORKSPACE

components:
  terraform:
    ${STACK_NAME}:
      metadata:
        component: "${STACK_NAME}"
        description: "Terraform workspace: $WORKSPACE"
      vars: {}
      backend:
        cloud:
          organization: "tf_jmakori"
          workspaces:
            name: "${STACK_NAME}"
EOF

echo "✅ Created stacks/${STACK_NAME}.yaml"

# Create component directory
mkdir -p "stacks/${STACK_NAME}"

# Generate component main.tf that references the workspace directory
# Build the variable passing section dynamically
VAR_PASSING=""
for var in $VARIABLES; do
    VAR_PASSING="${VAR_PASSING}  ${var} = var.${var}
"
done

cat > "stacks/${STACK_NAME}/main.tf" << EOF
# Component wrapper for $WORKSPACE workspace
# This references the actual Terraform code in the workspace directory

module "workspace" {
  source = "../../${WORKSPACE}"
  
  # Pass variables from workspace
${VAR_PASSING}
}

# Re-export workspace outputs
output "workspace_outputs" {
  description = "All outputs from the workspace"
  value       = module.workspace
}
EOF

echo "✅ Created stacks/${STACK_NAME}/main.tf"

# Generate component variables.tf dynamically based on workspace variables
# Extract variable definitions from workspace's variables.tf
VAR_DEFINITIONS=""
while IFS= read -r line; do
    VAR_DEFINITIONS="${VAR_DEFINITIONS}${line}
"
done < <(sed -n '/^variable/,/^}/p' "${WORKSPACE}/variables.tf")

cat > "stacks/${STACK_NAME}/variables.tf" << EOF
# Variables for component
# These are automatically extracted from the workspace's variables.tf

${VAR_DEFINITIONS}
EOF

echo "✅ Created stacks/${STACK_NAME}/variables.tf"

# Generate component versions.tf
cat > "stacks/${STACK_NAME}/versions.tf" << 'EOF'
terraform {
  required_version = ">= 1.0"
}
EOF

echo "✅ Created stacks/${STACK_NAME}/versions.tf"

echo ""
echo "✅ Atmos configuration generated successfully"
echo "   Workspace: $WORKSPACE"
echo "   Stack: ${STACK_NAME}"
echo "   Config directory: stacks/${STACK_NAME}/"
echo "   Variables detected: $(echo $VARIABLES | wc -w)"
echo ""
echo "Generated files:"
echo "  - atmos.yaml"
echo "  - stacks/${STACK_NAME}.yaml"
echo "  - stacks/${STACK_NAME}/"
