provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.tags
  }
}

data "tls_certificate" "gitlab" {
  url = "tls://gitlab.com:443"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.gitlab.certificates.0.sha1_fingerprint]
}

data "aws_iam_policy_document" "gitlab_repos" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession"
    ]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }
    condition {
      test     = "StringLike"
      variable = "${aws_iam_openid_connect_provider.gitlab.url}:sub"
      values   = var.gitlab_repos
    }
  }
}

resource "aws_iam_role" "gitlab_pipelines" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.gitlab_repos.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "merged_policies" {
  for_each   = var.role_policies
  role       = aws_iam_role.gitlab_pipelines.name
  policy_arn = each.value
}
