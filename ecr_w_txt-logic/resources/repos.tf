# State repos locally˜
locals {
  repositories = toset(split("\n", file("${path.module}/repos.txt")))
}

# Loops repos
resource "aws_ecr_repository" "myrepository" {
  # checkov:skip=CKV_AWS_136: AES-256	protected
  for_each = local.repositories
  name     = each.value
  image_scanning_configuration {
    scan_on_push = true
  }
  image_tag_mutability = "IMMUTABLE"
}


# Applies lifecycle policy to each repo
resource "aws_ecr_lifecycle_policy" "image_removal_policy" {
  for_each   = local.repositories
  repository = aws_ecr_repository.myrepository[each.value].name
  policy     = file("${path.module}/ecrpolicy-5max.json")
}