"""
Lambda function that periodically exports Zitadel audit events to S3.

Required environment variables:
  ZITADEL_URL            - Base URL of the Zitadel instance
  S3_BUCKET              - Destination S3 bucket name
  ZITADEL_TOKEN_SSM_PATH - SSM Parameter Store path for the Zitadel Bearer token

Optional environment variables:
  WINDOW_MINUTES - Duration of the collection window in minutes (default: 15)
"""

import json
import logging
import os
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import boto3

logging.getLogger().setLevel(logging.INFO)
logger = logging.getLogger()

# ---------------------------------------------------------------------------
# Module-level configuration (read once at cold start)
# ---------------------------------------------------------------------------

ZITADEL_URL: str = os.environ["ZITADEL_URL"]
S3_BUCKET: str = os.environ["S3_BUCKET"]
ZITADEL_TOKEN_SSM_PATH: str = os.environ["ZITADEL_TOKEN_SSM_PATH"]
WINDOW_MINUTES: int = int(os.environ.get("WINDOW_MINUTES", "15"))

# Bearer token cached after the first SSM read so subsequent warm invocations
# skip the SSM round-trip.
_bearer_token: str | None = None


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _get_now() -> datetime:
    """Return the current UTC time. Isolated to simplify unit testing."""
    return datetime.now(timezone.utc)


def _load_bearer_token() -> str:
    """Read the Zitadel Bearer token from SSM Parameter Store (cached)."""
    global _bearer_token
    if _bearer_token is None:
        logger.info("Loading Bearer token from SSM: %s", ZITADEL_TOKEN_SSM_PATH)
        ssm = boto3.client("ssm")
        response = ssm.get_parameter(Name=ZITADEL_TOKEN_SSM_PATH, WithDecryption=True)
        _bearer_token = response["Parameter"]["Value"]
        logger.info("Bearer token loaded successfully from SSM")
    else:
        logger.debug("Using cached Bearer token")
    return _bearer_token


def _compute_window(now: datetime, window_minutes: int) -> tuple[datetime, datetime]:
    """
    Return (window_start, window_end) for the most recently completed window
    aligned to *window_minutes* boundaries on the UTC clock.

    Example: now=15:22:45 with window_minutes=15 → (15:00:00, 15:15:00)
    """
    window_seconds = window_minutes * 60
    epoch_seconds = int(now.timestamp())
    window_end_epoch = (epoch_seconds // window_seconds) * window_seconds
    window_end = datetime.fromtimestamp(window_end_epoch, tz=timezone.utc)
    window_start = window_end - timedelta(minutes=window_minutes)
    return window_start, window_end


def _format_timestamp(dt: datetime) -> str:
    """Format a UTC datetime as an RFC 3339 string suitable for the Zitadel API."""
    return dt.strftime("%Y-%m-%dT%H:%M:%S.000000Z")


# ---------------------------------------------------------------------------
# Core logic
# ---------------------------------------------------------------------------


def fetch_events(base_url: str, token: str, window_start: datetime) -> list[dict]:
    """Fetch all events from the Zitadel Admin API on or after *window_start*."""
    url = f"{base_url.rstrip('/')}/events/_search"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    body: dict = {
        "from": _format_timestamp(window_start),
        "asc": True,
    }

    logger.info(
        "Fetching events from %s starting at %s",
        url,
        _format_timestamp(window_start),
    )

    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        method="POST",
        headers=headers,
    )

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        logger.error("HTTP %d error fetching events: %s", exc.code, exc.reason)
        raise
    except urllib.error.URLError as exc:
        logger.error("Network error fetching events: %s", exc.reason)
        raise

    events: list[dict] = result.get("events", [])
    logger.info("Fetched %d event(s)", len(events))
    return events


def save_to_s3(bucket: str, key: str, events: list[dict]) -> None:
    """Serialise *events* and write them to *key* in *bucket*."""
    logger.info("Saving %d event(s) to s3://%s/%s", len(events), bucket, key)
    s3 = boto3.client("s3")
    body = json.dumps({"events": events}, default=str).encode()
    s3.put_object(Bucket=bucket, Key=key, Body=body, ContentType="application/json")
    logger.info(
        "Successfully saved %d event(s) to s3://%s/%s", len(events), bucket, key
    )


# ---------------------------------------------------------------------------
# Lambda entry point
# ---------------------------------------------------------------------------


def handler(event: dict, context) -> dict:
    """Lambda handler — exported as the function entry point."""
    now = _get_now()
    window_start, window_end = _compute_window(now, WINDOW_MINUTES)
    logger.info(
        "Starting audit export: window=[%s, %s) window_minutes=%d",
        window_start.isoformat(),
        window_end.isoformat(),
        WINDOW_MINUTES,
    )

    token = _load_bearer_token()
    events = fetch_events(ZITADEL_URL, token, window_start)

    s3_key = f"events/{window_start.strftime('%Y/%m/%d/%H-%M-%S')}.json"
    save_to_s3(S3_BUCKET, s3_key, events)

    result = {
        "statusCode": 200,
        "events_count": len(events),
        "s3_key": s3_key,
        "window_start": window_start.isoformat(),
        "window_end": window_end.isoformat(),
    }
    logger.info("Audit export complete: %s", result)
    return result
