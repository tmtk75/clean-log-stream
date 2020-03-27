variable func_name {}
variable bin_name {}
variable iam_role_name {}

output iam_role_arn { value = aws_iam_role.main.arn }

locals {
  func_name = var.func_name
  bin_name  = var.bin_name
  actions = ["logs:Describe*"]
}

resource aws_iam_role main {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data aws_iam_policy_document assume_role {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource aws_iam_role_policy_attachment authn {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.authn.arn
}

resource aws_iam_policy authn {
  name = "${local.func_name}-policy"
  path = "/"
  # description = ""
  policy = data.aws_iam_policy_document.authn.json
}

data aws_iam_policy_document authn {
  statement {
    effect = "Allow"
    actions = concat([
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ], local.actions)
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

