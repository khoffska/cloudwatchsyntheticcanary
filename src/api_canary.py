import os

import urllib3
from aws_synthetics.common import synthetics_logger as logger


def main():
    endpoint = os.environ.get("API_ENDPOINT")
    method = os.environ.get("API_METHOD", "GET")
    if not endpoint:
        raise Exception("API_ENDPOINT environment variable is not set")

    logger.info(f"Making {method} request to {endpoint}")
    http = urllib3.PoolManager()
    response = http.request(method, endpoint)
    logger.info(f"Response status: {response.status}")

    if response.status < 200 or response.status > 299:
        raise Exception(f"{method} {endpoint} returned status {response.status}")
    logger.info("API canary successfully executed.")


def handler(event, context):
    logger.info("Python API heartbeat canary.")
    return main()
