package test

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const testWorkspaceName = "test-atmos-workspace"

// TestAtmosConfigGeneration validates the complete workflow:
// 1. Bootstrap a temporary "hello world" Atmos workspace
// 2. Run the config-generation script
// 3. Execute Terraform plan via Atmos
// 4. Execute Terraform apply via Atmos using cached plan
// 5. Execute Terraform destroy via apply -destroy
func TestAtmosConfigGeneration(t *testing.T) {
	// Setup: Create temporary test directory
	tempDir, err := os.MkdirTemp("", "terratest-atmos-")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)
	t.Logf("📁 Test directory: %s", tempDir)

	// Get repo root
	repoRoot, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get working directory: %v", err)
	}
	if strings.HasSuffix(repoRoot, "/test") || strings.HasSuffix(repoRoot, "/.test") {
		repoRoot = filepath.Dir(repoRoot)
	}
	t.Logf("📦 Repo root: %s", repoRoot)

	// Phase 1: Bootstrap minimal workspace
	t.Log("\n=== PHASE 1: Bootstrap Minimal Workspace ===")
	bootstrapWorkspace(t, tempDir)

	// Phase 2: Generate Atmos config
	t.Log("\n=== PHASE 2: Generate Atmos Configuration ===")
	generateAtmosConfig(t, tempDir, repoRoot)

	// Phase 3: Validate generated config
	t.Log("\n=== PHASE 3: Validate Generated Configuration ===")
	validateGeneratedConfig(t, tempDir)

	// Phase 4: Terraform plan
	t.Log("\n=== PHASE 4: Terraform Plan ===")
	executeTerraformPlan(t, tempDir)

	// Phase 5: Terraform apply using cached plan
	t.Log("\n=== PHASE 5: Terraform Apply (using cached plan) ===")
	executeTerraformApply(t, tempDir)

	// Phase 6: Terraform destroy using apply -destroy
	t.Log("\n=== PHASE 6: Terraform Destroy (using apply -destroy) ===")
	executeTerraformDestroy(t, tempDir)

	t.Log("\n✅ All phases completed successfully")
}

func bootstrapWorkspace(t *testing.T, tempDir string) {
	workspaceDir := filepath.Join(tempDir, testWorkspaceName)
	if err := os.MkdirAll(workspaceDir, 0755); err != nil {
		t.Fatalf("Failed to create workspace: %v", err)
	}

	files := map[string]string{
		"versions.tf": `terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
`,
		"variables.tf": `variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "hello-world"
}
`,
		"main.tf": `resource "null_resource" "hello_world" {
  triggers = {
    environment = var.environment
    project     = var.project_name
  }
}
`,
		"outputs.tf": `output "workspace_name" {
  value = var.project_name
}
`,
		"data.tf": `# Data sources
`,
	}

	for filename, content := range files {
		path := filepath.Join(workspaceDir, filename)
		if err := os.WriteFile(path, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to write %s: %v", filename, err)
		}
		t.Logf("✅ Created %s", filename)
	}
}

func generateAtmosConfig(t *testing.T, tempDir, repoRoot string) {
	scriptPath := filepath.Join(repoRoot, ".github", "scripts", "generate-atmos-config.sh")

	// Verify script exists
	if _, err := os.Stat(scriptPath); err != nil {
		t.Fatalf("Script not found: %s", scriptPath)
	}

	// Change to temp directory
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(tempDir); err != nil {
		t.Fatalf("Failed to change to temp directory: %v", err)
	}

	// Run script
	cmd := exec.Command("bash", scriptPath, testWorkspaceName)
	cmd.Dir = tempDir
	output, err := cmd.CombinedOutput()
	t.Logf("Script output:\n%s", string(output))
	if err != nil {
		t.Fatalf("Script failed: %v", err)
	}

	t.Log("✅ Atmos config generated")
}

func validateGeneratedConfig(t *testing.T, tempDir string) {
	stackName := strings.ReplaceAll(testWorkspaceName, "/", "-")

	checks := map[string]string{
		"atmos.yaml":                    filepath.Join(tempDir, "atmos.yaml"),
		"stack YAML":                    filepath.Join(tempDir, "stacks", stackName+".yaml"),
		"component directory":           filepath.Join(tempDir, "stacks", stackName),
		"component main.tf":             filepath.Join(tempDir, "stacks", stackName, "main.tf"),
		"component variables.tf":        filepath.Join(tempDir, "stacks", stackName, "variables.tf"),
		"component versions.tf":         filepath.Join(tempDir, "stacks", stackName, "versions.tf"),
	}

	for name, path := range checks {
		if _, err := os.Stat(path); err != nil {
			t.Fatalf("%s not found: %s", name, path)
		}
		t.Logf("✅ %s exists", name)
	}

	// Validate content
	mainTfPath := filepath.Join(tempDir, "stacks", stackName, "main.tf")
	content, err := os.ReadFile(mainTfPath)
	if err != nil {
		t.Fatalf("Failed to read main.tf: %v", err)
	}
	if !strings.Contains(string(content), "module") {
		t.Fatalf("main.tf missing module reference")
	}
	t.Log("✅ main.tf contains module reference")
}

func executeTerraformPlan(t *testing.T, tempDir string) {
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(tempDir); err != nil {
		t.Fatalf("Failed to change to temp directory: %v", err)
	}

	stackName := strings.ReplaceAll(testWorkspaceName, "/", "-")

	// Plan (atmos handles init automatically)
	// Stack name is passed with -s flag to specify the stack
	t.Log("📋 Running terraform plan...")
	planCmd := exec.Command("atmos", "terraform", "plan", "-s", stackName, stackName)
	planCmd.Dir = tempDir
	planOutput, err := planCmd.CombinedOutput()
	t.Logf("Plan output:\n%s", string(planOutput))
	if err != nil {
		t.Fatalf("Plan failed: %v", err)
	}

	// Verify plan artifacts are cached
	terraformDir := filepath.Join(tempDir, "stacks", stackName, ".terraform")
	if _, err := os.Stat(terraformDir); err != nil {
		t.Logf("⚠️  .terraform directory not found at %s (may be in parent)", terraformDir)
	} else {
		t.Logf("✅ Plan artifacts cached in .terraform directory")
	}

	t.Log("✅ Plan executed successfully")
}

func executeTerraformApply(t *testing.T, tempDir string) {
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(tempDir); err != nil {
		t.Fatalf("Failed to change to temp directory: %v", err)
	}

	stackName := strings.ReplaceAll(testWorkspaceName, "/", "-")

	t.Log("🚀 Running terraform apply with cached plan...")
	// Apply using the cached plan from plan phase
	// Stack name is passed with -s flag to specify the stack
	applyCmd := exec.Command("atmos", "terraform", "apply", "-s", stackName, stackName, "-auto-approve")
	applyCmd.Dir = tempDir
	applyOutput, err := applyCmd.CombinedOutput()
	t.Logf("Apply output:\n%s", string(applyOutput))
	if err != nil {
		t.Fatalf("Apply failed: %v", err)
	}

	t.Log("✅ Apply executed successfully with cached plan")
}

func executeTerraformDestroy(t *testing.T, tempDir string) {
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current directory: %v", err)
	}
	defer os.Chdir(originalDir)

	if err := os.Chdir(tempDir); err != nil {
		t.Fatalf("Failed to change to temp directory: %v", err)
	}

	stackName := strings.ReplaceAll(testWorkspaceName, "/", "-")

	t.Log("🗑️  Running terraform apply -destroy...")
	// Stack name is passed with -s flag to specify the stack
	destroyCmd := exec.Command("atmos", "terraform", "apply", "-s", stackName, stackName, "-destroy", "-auto-approve")
	destroyCmd.Dir = tempDir
	destroyOutput, err := destroyCmd.CombinedOutput()
	t.Logf("Destroy output:\n%s", string(destroyOutput))
	if err != nil {
		t.Fatalf("Destroy failed: %v", err)
	}

	t.Log("✅ Destroy executed successfully with apply -destroy")
}
