variable aws_profile {}
variable aws_region { default = "ap-northeast-1" }
variable prefix { default = "dev" }
variable log_group_name {}
variable last_event_time {}

provider aws {
  profile = var.aws_profile
  region  = var.aws_region
}

locals {
  prefix    = var.prefix
  bin_name  = "clean-log-stream"
  func_name = "${local.prefix}-${local.bin_name}"
  role_name = "${local.prefix}-lambda_exec"
}

resource aws_lambda_function handler {
  function_name    = local.func_name
  handler          = local.bin_name
  runtime          = "go1.x"
  filename         = data.archive_file.zip.output_path
  source_code_hash = filesha256(data.archive_file.zip.output_path)
  role             = module.iam_role.iam_role_arn

  environment {
    variables = {
      LOG_GROUP_NAME  = var.log_group_name
      LAST_EVENT_TIME = var.last_event_time
    }
  }
}

data archive_file zip {
  type        = "zip"
  source_file = "${path.module}/${local.bin_name}"
  output_path = "${path.module}/${local.bin_name}.zip"
}

# Ensure retention for the lambda func.
resource aws_cloudwatch_log_group handler {
  name              = "/aws/lambda/${local.func_name}"
  retention_in_days = 1
}

module iam_role {
  source        = "./iam_role"
  func_name     = local.func_name
  bin_name      = local.bin_name
  iam_role_name = local.role_name
}

module schedule {
  source    = "./schedule"
  func_name = local.func_name
  desc      = "Every 24 hours"
  expr      = "cron(0 * * * * *)" # or "rate(1 minute)"  https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#RateExpressions
  func_arn  = aws_lambda_function.handler.arn
}
