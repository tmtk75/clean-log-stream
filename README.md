# README
## What's this?
https://forums.aws.amazon.com/thread.jspa?threadID=178855

It seems still we need to delete stale log streams by ourselves.
This repository provides a way to keep deleting log streams created before the specified time. It's working as an AWS Lambda function. 

The function is written in golang and deployed by terraform.

Actually this is a template repository for such simple lambda function to deploy smoothly when I want such function. I sometimes wnat it but forget all and google how to write again :-|

Next time I'll clone this.

## What to provide
* An AWS Lambda function in golang.
  - uses AWS SDK v2
  - cobra/viper
* Terraform
  - Deploy a function.
  - Make an IAM role.
  - Make a CloudWatch schedule event.

## How to use
TBD