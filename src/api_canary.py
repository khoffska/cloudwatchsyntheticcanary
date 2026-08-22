import json
import os
import time

import urllib3
from aws_synthetics.common import synthetics_logger as logger

# Generic API canary. All behaviour is driven by environment variables so a
# single script can monitor any endpoint (see the api_canary env vars built in
# main.tf from each entry in var.cloudwatch_map):
#   API_ENDPOINT         (required) URL to request
#   API_METHOD           HTTP method (default GET)
#   API_REQUEST_HEADERS  JSON object of request headers (e.g. Authorization)
#   API_REQUEST_BODY     raw request body for POST/PUT
#   API_EXPECTED_STATUS  assert an exact status code instead of any 2xx
#   API_MAX_LATENCY_MS   fail if the response is slower than this
#   API_BODY_CONTAINS    assert this substring is present in the response body
#   API_JSON_ASSERTIONS  JSON object of dotted-path -> expected value assertions


def _json_path(data, dotted_key):
    """Walk a dotted path (e.g. "data.region" or "items.0.id") into parsed JSON."""
    current = data
    for part in dotted_key.split("."):
        current = current[int(part) if isinstance(current, list) else part]
    return current


def _check_status(status):
    expected = os.environ.get("API_EXPECTED_STATUS")
    if expected:
        if status != int(expected):
            raise Exception(f"Expected status {expected} but got {status}")
    elif status < 200 or status > 299:
        raise Exception(f"Expected a 2xx status but got {status}")


def _check_latency(latency_ms):
    max_latency = os.environ.get("API_MAX_LATENCY_MS")
    if max_latency and latency_ms > float(max_latency):
        raise Exception(
            f"Response took {latency_ms:.0f} ms, exceeding the {max_latency} ms threshold"
        )


def _check_body(response):
    substring = os.environ.get("API_BODY_CONTAINS")
    json_assertions = os.environ.get("API_JSON_ASSERTIONS")
    if not substring and not json_assertions:
        return

    text = response.data.decode("utf-8", errors="replace")

    if substring and substring not in text:
        raise Exception(f'Response body did not contain expected text: "{substring}"')

    if json_assertions:
        parsed = json.loads(text)
        for key, expected in json.loads(json_assertions).items():
            actual = _json_path(parsed, key)
            if str(actual) != str(expected):
                raise Exception(
                    f'JSON field "{key}" was "{actual}", expected "{expected}"'
                )


def main():
    endpoint = os.environ.get("API_ENDPOINT")
    if not endpoint:
        raise Exception("API_ENDPOINT environment variable is not set")

    method = os.environ.get("API_METHOD", "GET")
    headers = json.loads(os.environ.get("API_REQUEST_HEADERS", "{}"))
    body = os.environ.get("API_REQUEST_BODY")

    logger.info(f"Making {method} request to {endpoint}")
    http = urllib3.PoolManager()

    start = time.monotonic()
    # Hard timeout so a stalled connection fails fast instead of hanging until
    # the Lambda timeout kills the canary mid-run (no results, no S3 artifacts).
    response = http.request(
        method, endpoint, headers=headers, body=body,
        timeout=urllib3.Timeout(connect=5, read=15),
    )
    latency_ms = (time.monotonic() - start) * 1000
    logger.info(f"Response status: {response.status} in {latency_ms:.0f} ms")

    _check_status(response.status)
    _check_latency(latency_ms)
    _check_body(response)

    logger.info("API canary successfully executed.")


def handler(event, context):
    logger.info("Python API heartbeat canary.")
    return main()
