terraform {
  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "oci_maklab_base0"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }

    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.13.0"
    }

    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.9.0"
    }
  }
}

