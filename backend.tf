terraform {
  backend "s3" {
    bucket  = "nyon-terraform-state-bucket"
    key     = "azure-terraform-state.tfstate"
    region  = "us-west-1"
    workspace_key_prefix = "workspaces"
    #profile = var.aws_profile
  }
}