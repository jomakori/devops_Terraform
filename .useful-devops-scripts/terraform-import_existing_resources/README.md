# Terraform Existing Resource Importer

> **IMPORTANT:** Please use this script responsibly. Importing resources directly into Terraform might affect your existing infrastructure. Please ensure that the resource you're importing aligns with your defined Terraform configurations.

## Overview

This bash script allows us to batch import existing (unmanaged) AWS resources into Terraform by the resource names fed into the program. The resource names are read from the `import_resources.csv` file.

This script does two main things:

1. **Reads Resource Names**: The script reads the resource names from the`import_resources.csv` file. 
   - The left column `resource_name` is where you would provide the name of your resources. 
   - The right column `resource_uid` is where you would provide the `import id` (each type of resource differs). See the [provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for more info.

2. **Imports Resources**: The script runs a `terraform import` command for each resource. It imports the existing resource to the Terraform state.

## Requirements

- Bash shell (Linux/MacOS)
- Terraform cli installed on your system.
- AWS CLI configured with appropriate AWS credentials.

## How to Run

***Before you run the script, you must fill out the `import_resources.csv` sheet.*** On the left column `resource_name` fill out the list of terraform resource names. On the right column `resource_uid`, fill out the `import id` (each type of resource differs). See the [provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for more info (import details provided on the bottom of the resource page). Leave a blank line at the end of the list for formatting purposes.

**To run this script**, navigate to the directory containing the script and run the following command:

```bash
./import_resources.sh
```

***The script will first prompt you to enter the name of the [resource type ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)you're wishing to import.*** Then, it will process the CSV file and run a `terraform import` command for each resource.

Please ensure that the AWS CLI is configured properly with the appropriate credentials. The script will use these credentials to interact with the AWS services.

Please also ensure that your Terraform configurations align with the resources that you are importing. This script does not perform any checks or validations on the imported resources, so it's important to verify the resources yourself to prevent any issues.
