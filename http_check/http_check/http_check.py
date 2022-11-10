"""Lambda that performs an HTTP check on an endpoint"""

import os
from datetime import datetime

import boto3
import requests


def check_endpoint(endpoint: str) -> str:
    """Make an HTTP GET request to endpoint and return the status code

    Args:
        endpoint: The HTTP endpoint to check.

    Returns:
        The HTTP status code returned by the endpoint.
    """

    return str(requests.get(endpoint).status_code)


def put_metric_data(metric_name: str, value: int, region: str) -> dict:
    """Send metric data to the Cloudwatch API

    Args:
        metric_name: The name of the Cloudwatch metric.
        http_status_code: The HTTP status code returned by check_endpoint().
        region: The region to send the metric to.

    Returns:
        A dict with the PutMetricData response.
    """

    client = boto3.client("cloudwatch", region_name=region)
    response = client.put_metric_data(
        Namespace=metric_name,
        MetricData=[
            {
                "MetricName": metric_name,
                "Timestamp": datetime.now(),
                "Value": int(value),
            }
        ],
    )
    return response


def handler(event, context):
    """Lambda handler

    Args:
        event: AWS event invoking the lambda.
        context: Provides methods and properties that provide information about the invocation, function, and runtime environment.
    """

    region = os.environ["AWS_REGION"]
    health_check_endpoint = os.environ["HEALTH_CHECK_ENDPOINT"]
    metric_name = os.environ["METRIC_NAME"]
    acceptable_return_codes = os.environ.get("ACCEPTABLE_RETURN_CODES")

    http_status_code = check_endpoint(health_check_endpoint)
    print(f"HTTP status code: {http_status_code}")
    if http_status_code not in acceptable_return_codes:
        put_metric_data(metric_name, 1, region)
        # TODO: send message to SNS with payload on failure
    else:
        put_metric_data(metric_name, 0, region)

    response = put_metric_data(metric_name, http_status_code, region)
    print(f"PutMetricData Response: {response}")


if __name__ == "__main__":
    handler("", "")
