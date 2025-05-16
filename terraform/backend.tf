terraform {
  cloud {
    organization = "killian-vienne-org"
    workspaces {
      name = "T-SEC-902-Terraform-state"
    }
  }
}