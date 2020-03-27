variable func_name { description = "used as name of resource." }
variable func_arn {}
variable desc {}
variable expr {}

resource aws_cloudwatch_event_rule main {
  name                = var.func_name
  description         = var.desc
  schedule_expression = var.expr # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions
}

resource aws_lambda_permission main {
  statement_id  = var.func_name
  action        = "lambda:InvokeFunction"
  function_name = aws_cloudwatch_event_target.main.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}

resource aws_cloudwatch_event_target main {
  target_id = aws_cloudwatch_event_rule.main.name
  rule      = aws_cloudwatch_event_rule.main.name
  arn       = var.func_arn
}
