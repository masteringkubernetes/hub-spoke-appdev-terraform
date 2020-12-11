
locals {
  # All variables used in this file should be 
  # added as locals here 
  location        = var.location
  prefix          = var.prefix != null ? var.prefix : random_pet.petname.id 
  vault_name      = "${local.prefix}-vault"
  registry_name   = "${local.prefix}-acr"
  # Common tags should go here
  tags            = {
    created_by    = "Terraform"
  }
}