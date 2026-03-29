#!/bin/bash
set -e

# Script to generate Atmos configuration at runtime
# Usage: ./generate-atmos-config.sh <workspace-name>
# 
# This script creates the Atmos configuration structure that wraps existing Terraform workspaces
# It dynamically detects required variables from each workspace's variables.tf file
# Configuration is generated at repository root in the stacks/ directory

WORKSPACE="${1:?Workspace name required}"

# Defaults for Terraform Cloud wrapper-root configuration
DEFAULT_TFC_ORGANIZATION="tf_jmakori"

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

# Detect Terraform Cloud organization from workspace (if present)
TFC_ORGANIZATION=$(grep -oP 'organization\s*=\s*"\K[^"]+' "${WORKSPACE}/versions.tf" 2>/dev/null | head -1 || true)
TFC_ORGANIZATION=${TFC_ORGANIZATION:-$DEFAULT_TFC_ORGANIZATION}

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

# Build variable assignments for the stack YAML with proper indentation (8 spaces)
VAR_ASSIGNMENTS=""
for var in $VARIABLES; do
    VAR_ASSIGNMENTS="${VAR_ASSIGNMENTS}        ${var}: \${{ var.${var} }}
"
done

# Remove trailing newline if present
VAR_ASSIGNMENTS=$(echo "$VAR_ASSIGNMENTS" | sed '$ s/\n$//')

cat > "stacks/${STACK_NAME}.yaml" << EOF
# Stack configuration for workspace: $WORKSPACE

components:
  terraform:
    ${STACK_NAME}:
      metadata:
        component: "${STACK_NAME}"
        description: "Terraform workspace: $WORKSPACE"
      vars:
${VAR_ASSIGNMENTS}
EOF

echo "✅ Created stacks/${STACK_NAME}.yaml"

# Create component directory
mkdir -p "stacks/${STACK_NAME}"

# Build a sanitized copy of the workspace as child module source.
# This removes `terraform { cloud { ... } }` from child module files,
# because cloud blocks must exist only in the root module.
SANITIZED_SRC_DIR="stacks/${STACK_NAME}/_workspace_src"
rm -rf "$SANITIZED_SRC_DIR"
mkdir -p "$SANITIZED_SRC_DIR"
cp -R "${WORKSPACE}/." "$SANITIZED_SRC_DIR/"

strip_cloud_block() {
    local file_path="$1"
    python3 - "$file_path" << 'PY'
import re
import sys

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
i = 0
while i < len(lines):
    line = lines[i]
    if re.match(r'^\s*cloud\s*\{\s*$', line):
        depth = line.count('{') - line.count('}')
        i += 1
        while i < len(lines) and depth > 0:
            depth += lines[i].count('{') - lines[i].count('}')
            i += 1
        continue
    out.append(line)
    i += 1

with open(path, 'w', encoding='utf-8') as f:
    f.write(''.join(out))
PY
}

# Strip child-module cloud blocks from top-level Terraform files in copied source
for tf_file in "$SANITIZED_SRC_DIR"/*.tf; do
    [ -f "$tf_file" ] || continue
    strip_cloud_block "$tf_file"
done

# Generate component main.tf that references the sanitized workspace directory
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
  source = "./_workspace_src"
  
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
cat > "stacks/${STACK_NAME}/versions.tf" << EOF
terraform {
  cloud {
    organization = "${TFC_ORGANIZATION}"

    workspaces {
      name = "${STACK_NAME}"
    }
  }

  required_version = ">= 1.0"
}
EOF

echo "✅ Created stacks/${STACK_NAME}/versions.tf"

echo ""
echo "✅ Atmos configuration generated successfully"
echo "   Workspace: $WORKSPACE"
echo "   Stack: ${STACK_NAME}"
echo "   Terraform Cloud organization: ${TFC_ORGANIZATION}"
echo "   Config directory: stacks/${STACK_NAME}/"
echo "   Variables detected: $(echo $VARIABLES | wc -w)"
echo ""
echo "Generated files:"
echo "  - atmos.yaml"
echo "  - stacks/${STACK_NAME}.yaml"
echo "  - stacks/${STACK_NAME}/"
