import os

import boto3
import pytest
from moto import mock_cloudwatch

from http_check import __version__
from http_check.http_check import check_endpoint, put_metric_data


@pytest.fixture(scope="function")
def aws_credentials():
    """Mocked AWS Credentials for moto."""

    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-2"


@pytest.fixture(scope="function")
def cloudwatch_client(aws_credentials):
    with mock_cloudwatch():
        yield boto3.client("cloudwatch", region_name="us-east-2")


def test_version():
    assert __version__ == "0.1.0"


def test_check_endpoint_bad_endpoint():
    r = check_endpoint("http://127.0.0.1")
    assert r == "-1"


def test_check_endpoint_good_endpoint():
    r = check_endpoint("https://google.com")
    assert r == "200"


def test_put_metric_data(cloudwatch_client):
    response = put_metric_data(cloudwatch_client, "pytest", "pytest-test", 1)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
