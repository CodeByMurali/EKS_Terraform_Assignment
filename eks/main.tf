locals {
  project = "hiive"
  env     = var.env
}

module "eks" {
  source = "../module"

}
