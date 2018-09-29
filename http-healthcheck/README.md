## Usage
```hcl
provider "aws" {
  region = "us-west-2"
}

module "healthcheck" {
  source = "./http-healthcheck"

  app_name             = "testapp"
  region               = "us-west-2"
  healthcheck_endpoint = "https://example.com"
  alert_endpoint       = "https://example.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alert_endpoint | The alert endpoint (VictorOps, Pagerduty, etc). | string | - | yes |
| app_name | The name of the app you're testing. This will be used to name AWS resources so it should be unique. | string | - | yes |
| healthcheck_endpoint | The endpoint to check. | string | - | yes |
| region | The AWS region to deploy the check to. | string | - | yes |


