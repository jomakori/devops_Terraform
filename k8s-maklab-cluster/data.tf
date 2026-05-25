data "cloudflare_zone" "maklab" {
  filter = {
    name = var.gitops_config["clusterDomain"]
  }
}
