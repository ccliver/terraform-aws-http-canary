"""Lambda that performs an HTTP check on an endpoint"""

import os
import datetime

import boto3
from botocore.exceptions import ClientError
import requests

from aws_lambda_powertools import Logger


logger = Logger()
cloudwatch = boto3.client("cloudwatch", region_name=os.getenv("REGION", "us-east-1"))
sns = boto3.client("sns", region_name=os.getenv("REGION", "us-east-1"))


def check_endpoint(endpoint: str, ok_return_codes: list[int], timeout: int = 5) -> int:
    """Make an HTTP GET request to endpoint and return the status code

    Args:
        endpoint: The HTTP endpoint to check.

    Returns:
        The HTTP status code returned by the endpoint or -1 if the endpoint could not be reached.
    """

    logger.info(f"Checking endpoint {endpoint}")
    try:
        response = requests.get(endpoint, timeout=timeout)
        return response.status_code
    except requests.RequestException as err:
        logger.exception(f"Error accessing endpoint: {err}")
        return -1


def put_metric_data(
    namespace: str, name: str, value: int, dimensions: list[dict] = []
) -> dict:
    """Send metric data to the Cloudwatch API

    Args:
        metric_namespace: The namespace the metric should be under.
        metric_name: The name of the Cloudwatch metric.
        http_status_code: The HTTP status code returned by check_endpoint().

    Returns:
        A dict with the PutMetricData response.
    """

    logger.info(
        f"Putting metric data: Namespace={namespace}, Name={name}, Value={value}, Dimensions={dimensions}"
    )
    try:
        response = cloudwatch.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    "Dimensions": dimensions,
                    "MetricName": name,
                    "Timestamp": datetime.datetime.now(datetime.UTC),
                    "Value": int(value),
                }
            ],
        )
    except ClientError as err:
        logger.exception(f"Error sending metric data to Cloudwatch: {err}")
        raise
    return response


@logger.inject_lambda_context(log_event=True)
def handler(event, context):
    """Lambda handler"""

    try:
        health_check_endpoint = os.environ["ENDPOINT"]
        metric_name = os.environ["METRIC_NAME"]
        ok_return_codes = [
            int(code) for code in os.environ.get("OK_RETURN_CODES", "").split(",")
        ]
    except KeyError as err:
        logger.exception(f"Missing required environment variable: {err}")
        raise
    metric_dimensions = os.getenv("METRIC_DIMENSIONS", "")
    metric_dimensions = [
        {"Name": dim.split("=")[0], "Value": dim.split("=")[1]}
        for dim in metric_dimensions.split(",")
        if "=" in dim
    ]
    logger.info(f"Metric dimensions: {metric_dimensions}")
    topic_arn = os.getenv("SNS_TOPIC_ARN", "")
    metric_namespace = os.getenv("METRIC_NAMESPACE", "")
    request_timeout = int(os.getenv("REQUEST_TIMEOUT", "5"))

    http_status_code = check_endpoint(
        health_check_endpoint, ok_return_codes, request_timeout
    )
    logger.info(f"HTTP status code: {http_status_code}")
    logger.info(f"Acceptable return codes: {ok_return_codes}")
    if http_status_code not in ok_return_codes:
        logger.error(
            f"Did not receive an acceptable response from {health_check_endpoint}"
        )
        response = put_metric_data(metric_namespace, metric_name, 1, metric_dimensions)
        if topic_arn:
            sns.publish(
                TopicArn=topic_arn,
                Subject=f"Canary Alert: {health_check_endpoint} is down",
                Message=(
                    f"Canary detected an issue when accessing {health_check_endpoint}.\n"
                    f"Received HTTP status code: {http_status_code}\n"
                    f"Acceptable return codes: {ok_return_codes}"
                ),
            )
    else:
        response = put_metric_data(metric_namespace, metric_name, 0, metric_dimensions)
    logger.info(f"PutMetricData Response: {response}")
