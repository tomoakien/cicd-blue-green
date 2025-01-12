resource "aws_s3_bucket" "artifact" {
  bucket        = "terraform-codepipeline-github-artifact"
  force_destroy = true
}
