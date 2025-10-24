import pytest
from botocore.exceptions import ParamValidationError
from moto import mock_aws
import responses
import requests

from canary.main import check_endpoint, put_metric_data


@responses.activate
def test_check_endpoint_bad_endpoint():
    responses.add(
        responses.GET,
        "https://bad-test-endpoint",
        body=requests.exceptions.ConnectionError("Failed to connect"),
        status=500,
    )

    r = check_endpoint("https://bad-test-endpoint")
    assert r == -1


@responses.activate
def test_check_endpoint_good_endpoint():
    responses.add(
        responses.GET,
        "https://good-test-endpoint",
        body="Success",
        status=200,
    )

    r = check_endpoint("https://good-test-endpoint")
    assert r == 200


@mock_aws
def test_put_metric_data():
    response = put_metric_data("pytest", "pytest-test", 1)
    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


@mock_aws
def test_put_metric_data_invalid_parameters():
    with pytest.raises(ParamValidationError):
        put_metric_data("", "", -1)
