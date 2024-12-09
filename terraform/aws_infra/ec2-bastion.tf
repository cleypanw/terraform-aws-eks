#########
# EC2 configuration

resource "aws_key_pair" "ssh_key" {
  key_name   = local.sshkey_name
  public_key = "${var.public_ssh_key}"
  tags = {
    yor_trace = "884decc7-55f1-4cde-b057-ff57573b8a49"
  }
}

resource "aws_instance" "ec2instance" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.public_subnets[0]
  private_ip             = "10.0.4.10"
  vpc_security_group_ids = ["${aws_security_group.ec2-bastion.id}"]

  #checkov:skip=CKV_AWS_88
  associate_public_ip_address = true

  key_name = "${aws_key_pair.ssh_key.key_name}"

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
    encrypted             = true
  }

  # https://docs.bridgecrew.io/docs/bc_aws_general_31
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  depends_on = [
    aws_key_pair.ssh_key
  ]

  tags = {
    Name      = local.ec2_bastion_name
    yor_trace = "454b6450-ac02-4e65-9077-a4590b1b616e"
  }
}