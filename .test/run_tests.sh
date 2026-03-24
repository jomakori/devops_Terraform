#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Test directory: $SCRIPT_DIR"
echo "📦 Repo root: $REPO_ROOT"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v go >/dev/null 2>&1 || { echo "❌ Go not found"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found"; exit 1; }
command -v atmos >/dev/null 2>&1 || { echo "❌ Atmos not found"; exit 1; }
echo "✅ All prerequisites found"
echo ""

# Run tests
cd "$SCRIPT_DIR"
echo "🧪 Running Terratest suite..."
go test -v -timeout 600s -run TestAtmosConfigGeneration ./...
