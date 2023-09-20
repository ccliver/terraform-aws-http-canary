"""Lambda that performs an HTTP check on an endpoint"""

import os
from datetime import datetime

import boto3
import urllib3

from aws_lambda_powertools import Logger


logger = Logger()


def check_endpoint(endpoint: str) -> str:
    """Make an HTTP GET request to endpoint and return the status code

    Args:
        endpoint: The HTTP endpoint to check.

    Returns:
        The HTTP status code returned by the endpoint or -1 if the endpoint could not be reached.
    """

    logger.info(f"Checking endpoint {endpoint}")
    try:
        http = urllib3.PoolManager()
        r = http.request("GET", endpoint)
    except Exception as err:
        logger.error(f"Error accessing endpoint: {err}")
        return str("-1")

    return str(r.status)


def put_metric_data(metric_namespace: str, metric_name: str, value: int) -> dict:
    """Send metric data to the Cloudwatch API

    Args:
        metric_namespace: The namespace the metric should be under.
        metric_name: The name of the Cloudwatch metric.
        http_status_code: The HTTP status code returned by check_endpoint().

    Returns:
        A dict with the PutMetricData response.
    """

    client = boto3.client("cloudwatch")
    response = client.put_metric_data(
        Namespace=metric_namespace,
        MetricData=[
            {
                "MetricName": metric_name,
                "Timestamp": datetime.now(),
                "Value": int(value),
            }
        ],
    )
    return response


@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    """Lambda handler

    Args:
        event: AWS event invoking the lambda.
        context: Provides methods and properties that provide information about the invocation, function, and runtime environment.
    """

    health_check_endpoint = os.environ["HEALTH_CHECK_ENDPOINT"]
    metric_namespace = os.environ["METRIC_NAMESPACE"]
    metric_name = os.environ["METRIC_NAME"]
    acceptable_return_codes = os.environ.get("ACCEPTABLE_RETURN_CODES")

    http_status_code = check_endpoint(health_check_endpoint)
    logger.info(f"HTTP status code: {http_status_code}")
    logger.info(f"Acceptable return codes: {acceptable_return_codes}")
    if http_status_code not in acceptable_return_codes:
        logger.error(f"Did not receive an acceptable response from {health_check_endpoint}")
        response = put_metric_data(metric_namespace, metric_name, 1)
        # TODO: send message to SNS with payload on failure
    else:
        response = put_metric_data(metric_namespace, metric_name, 0)
    logger.info(f"PutMetricData Response: {response}")
