Lambda to perform an HTTP health check and alert an SNS topic on failure.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_metric_alarm.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_policy.cloudwatch_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.cloudwatch_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.test-attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_sns_topic.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [null_resource.build_package](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_endpoint"></a> [alert\_endpoint](#input\_alert\_endpoint) | The HTTP alert endpoint or email address. | `string` | n/a | yes |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the app you're testing. This will be used to name AWS resources so it should be unique. | `string` | n/a | yes |
| <a name="input_cloudwatch_dimensions"></a> [cloudwatch\_dimensions](#input\_cloudwatch\_dimensions) | A map of key=value pairs to use as dimensions for the CloudWatch metric. | `map(string)` | `{}` | no |
| <a name="input_cloudwatch_metric_name"></a> [cloudwatch\_metric\_name](#input\_cloudwatch\_metric\_name) | The name of the CloudWatch metric. | `string` | `null` | no |
| <a name="input_cloudwatch_metric_namespace"></a> [cloudwatch\_metric\_namespace](#input\_cloudwatch\_metric\_namespace) | The namespace to put the CloudWatch metric under. | `string` | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | The HTTP endpoint to check. | `string` | n/a | yes |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds. | `number` | `5` | no |
| <a name="input_ok_return_codes"></a> [ok\_return\_codes](#input\_ok\_return\_codes) | List of HTTP return codes indicating the health check was a success. | `list(number)` | <pre>[<br/>  200<br/>]</pre> | no |
| <a name="input_request_timeout"></a> [request\_timeout](#input\_request\_timeout) | Timeout in seconds for GET request to endpoitn. | `string` | `5` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | The [scheduling expression](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html). For example, cron(0 20 * * ? *) or rate(5 minutes). | `string` | `"rate(1 minute)"` | no |
| <a name="input_sns_subscription_protocol"></a> [sns\_subscription\_protocol](#input\_sns\_subscription\_protocol) | The SNS subscription protocol (email or http). | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
