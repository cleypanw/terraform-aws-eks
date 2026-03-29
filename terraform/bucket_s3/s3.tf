resource "aws_s3_bucket" "s3-tfstate" {
  bucket = local.s3_name
  tags = {
    Name      = "s3-bucket-for-tfstate"
    yor_trace = "22565d10-f714-4bc0-bbad-1197bde4ec48"
  }
}

resource "aws_s3_bucket_public_access_block" "s3-tfstate" {
  bucket              = aws_s3_bucket.s3-tfstate.id
  block_public_acls   = false
  block_public_policy = false
}
