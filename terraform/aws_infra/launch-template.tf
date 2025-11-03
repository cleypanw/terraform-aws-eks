resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${local.cluster_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.worker_nodes_type
  key_name      = local.sshkey_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2-bastion.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.cluster_name}-node"
    }
  }
}
