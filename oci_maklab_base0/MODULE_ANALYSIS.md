# OCI Terraform Modules Analysis

## Module Compatibility Report

### 1. VCN Module (oracle-terraform-modules/vcn/oci)
**Version:** ~> 3.0  
**Status:** ✅ COMPATIBLE

**Key Attributes:**
- Input: `subnets` (map of subnet configurations)
- Output: `subnet_id` - Returns a map keyed by display_name with subnet IDs
- Output: `vcn_id` - VCN ID
- Output: `internet_gateway_id` - IGW ID

**Usage Pattern:**
```hcl
module.vcn.subnet_id["public"]  # Access subnet by display_name
```

**Limitations:** None for our use case

---

### 2. Compute Instance Module (oracle-terraform-modules/compute-instance/oci)
**Version:** ~> 2.4  
**Status:** ✅ COMPATIBLE

**Required Inputs:**
- `compartment_ocid` - Compartment OCID
- `source_ocid` - Image OCID
- `subnet_ocids` - List of subnet OCIDs (required as list)
- `instance_display_name` - Display name for instance

**Optional Inputs:**
- `instance_count` - Number of instances (default: 1)
- `ad_number` - Availability domain number
- `shape` - Instance shape
- `instance_flex_ocpus` - OCPU count for flexible shapes
- `instance_flex_memory_in_gbs` - Memory for flexible shapes
- `ssh_public_keys` - SSH public keys
- `user_data` - Base64-encoded cloud-init script
- `public_ip` - NONE, RESERVED, or EPHEMERAL
- `block_storage_sizes_in_gbs` - List of block volume sizes
- `freeform_tags` - Tags

**Outputs:**
- `instance_id` - Instance OCID
- `public_ip` - Public IP address
- `private_ip` - Private IP address
- `instances_summary` - Summary of all instances

**Limitations:**
- Does NOT support `shape_config` block directly
- Flexible shapes use `instance_flex_ocpus` and `instance_flex_memory_in_gbs` instead
- Block volumes are created and attached automatically via `block_storage_sizes_in_gbs`

---

### 3. Logging Module (oracle-terraform-modules/logging/oci)
**Version:** ~> 0.4  
**Status:** ⚠️ LIMITED COMPATIBILITY

**Required Inputs:**
- `tenancy_id` - Tenancy OCID
- `service_logdef` - Service log definitions (complex structure)

**Optional Inputs:**
- `log_group_name` - Log group name
- `log_group_description` - Description
- `freeform_tags` - Tags

**Limitations:**
- Module is designed for OCI service logs (e.g., VCN Flow Logs, Load Balancer logs)
- Does NOT support custom CUSTOM log types
- Does NOT support arbitrary log configuration
- Parser types have limited support (regex, grok patterns not fully supported)
- Not suitable for application-level logging from cloud-init

**Recommendation:** Use raw OCI resources for custom logging instead

---

## Implementation Strategy

### ✅ Use Modules For:
1. **VCN** - Full module support with subnet mapping
2. **Compute Instance** - Full module support with flexible shapes
3. **Logging** - Module supports custom Linux logs via `linux_logdef`

### ⚠️ Use Raw Resources For:
1. **Security Lists** - Not covered by modules, use raw resources

---

## Configuration Summary

| Component | Approach | Module | Version |
|-----------|----------|--------|---------|
| VCN | Module | oracle-terraform-modules/vcn/oci | ~> 3.0 |
| Subnets | Module (via VCN) | oracle-terraform-modules/vcn/oci | ~> 3.0 |
| Compute Instance | Module | oracle-terraform-modules/compute-instance/oci | ~> 2.4 |
| Block Volumes | Module (via Compute) | oracle-terraform-modules/compute-instance/oci | ~> 2.4 |
| Security Lists | Raw Resource | oci_core_security_list | N/A |
| Logging | Module | oracle-terraform-modules/logging/oci | ~> 0.4 |

