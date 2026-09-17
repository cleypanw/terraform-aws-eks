# Render files from template
# `data "template_file"` relies on the archived hashicorp/template provider;
# the built-in templatefile() function replaces it with no provider dependency.
locals {
  ansible_inventory = templatefile("${path.module}/template/ansible-inventory.tpl", {
    ec2instance_public_ip = aws_instance.ec2instance.public_ip
  })

  cluster_name_file = templatefile("${path.module}/template/cluster-name.tpl", {
    cluster_name = module.eks.cluster_name
  })
}

# Upload objects (inventory + cluster) to S3
resource "aws_s3_object" "ansible_inventory" {
  bucket  = local.s3_name
  key     = "ansible_inventory.ini"
  content = local.ansible_inventory
}

resource "aws_s3_object" "cluster_name" {
  bucket  = local.s3_name
  key     = "cluster_name.txt"
  content = local.cluster_name_file
}
