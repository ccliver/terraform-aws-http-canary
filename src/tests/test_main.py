import os

import boto3
import pytest
from moto import mock_cloudwatch

from http_check import __version__
from http_check.main import check_endpoint, put_metric_data


os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "us-east-2"


def test_version():
    assert __version__ == "0.1.0"


def test_check_endpoint_bad_endpoint(requests_mock):
    r = check_endpoint("http://google.badurl")
    assert r == "-1"


def test_check_endpoint_good_endpoint(requests_mock):
    requests_mock.get("https://good-test-endpoint", text="OK", status_code=200)
    r = check_endpoint("https://good-test-endpoint")
    assert r == "200"


@mock_cloudwatch
def test_put_metric_data():
    response = put_metric_data("pytest", "pytest-test", 1)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200
