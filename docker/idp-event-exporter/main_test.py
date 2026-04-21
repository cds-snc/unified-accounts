"""
Unit tests for the Zitadel audit-event exporter Lambda function.

Environment variables required by the module are set before import so the
tests are self-contained and do not need any real AWS credentials or network
access.
"""

import json
import os
import unittest
from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

# ---------------------------------------------------------------------------
# Inject required environment variables before importing the module under test
# ---------------------------------------------------------------------------
os.environ.setdefault("ZITADEL_URL", "https://idp.example.com")
os.environ.setdefault("S3_BUCKET", "test-audit-bucket")
os.environ.setdefault("ZITADEL_TOKEN_SSM_PATH", "/platform/idp/bearer-token")

import main
from main import (
    _compute_window,
    _format_timestamp,
    fetch_events,
    handler,
    save_to_s3,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_event(ts_str: str, sequence: int = 1) -> dict:
    return {
        "sequence": sequence,
        "creationDate": ts_str,
        "type": {"type": "user.created"},
        "editor": {"userId": "u1", "displayName": "Alice"},
        "aggregate": {"id": "agg1", "type": {"type": "user"}},
    }


def _mock_urlopen(response_body: dict):
    """Return a context-manager mock that yields *response_body* as JSON bytes."""
    mock_resp = MagicMock()
    mock_resp.read.return_value = json.dumps(response_body).encode()
    mock_resp.__enter__ = lambda s: s
    mock_resp.__exit__ = MagicMock(return_value=False)
    return mock_resp


# ---------------------------------------------------------------------------
# _compute_window
# ---------------------------------------------------------------------------


class TestComputeWindow(unittest.TestCase):
    def test_aligns_to_15_minute_boundary(self):
        now = datetime(2026, 4, 21, 15, 22, 45, tzinfo=timezone.utc)
        start, end = _compute_window(now, 15)
        self.assertEqual(start, datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc))
        self.assertEqual(end, datetime(2026, 4, 21, 15, 15, 0, tzinfo=timezone.utc))

    def test_aligns_to_30_minute_boundary(self):
        now = datetime(2026, 4, 21, 15, 45, 0, tzinfo=timezone.utc)
        start, end = _compute_window(now, 30)
        self.assertEqual(start, datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc))
        self.assertEqual(end, datetime(2026, 4, 21, 15, 30, 0, tzinfo=timezone.utc))

    def test_exactly_on_boundary_returns_previous_window(self):
        # At exactly 15:15:00 the completed window is 15:00–15:15.
        now = datetime(2026, 4, 21, 15, 15, 0, tzinfo=timezone.utc)
        start, end = _compute_window(now, 15)
        self.assertEqual(start, datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc))
        self.assertEqual(end, datetime(2026, 4, 21, 15, 15, 0, tzinfo=timezone.utc))

    def test_window_duration_equals_window_minutes(self):
        now = datetime(2026, 4, 21, 9, 7, 0, tzinfo=timezone.utc)
        start, end = _compute_window(now, 15)
        from datetime import timedelta

        self.assertEqual(end - start, timedelta(minutes=15))

    def test_configurable_5_minute_window(self):
        now = datetime(2026, 4, 21, 15, 8, 30, tzinfo=timezone.utc)
        start, end = _compute_window(now, 5)
        self.assertEqual(start, datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc))
        self.assertEqual(end, datetime(2026, 4, 21, 15, 5, 0, tzinfo=timezone.utc))


# ---------------------------------------------------------------------------
# _format_timestamp
# ---------------------------------------------------------------------------


class TestFormatTimestamp(unittest.TestCase):
    def test_formats_to_rfc3339(self):
        dt = datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc)
        self.assertEqual(_format_timestamp(dt), "2026-04-21T15:00:00.000000Z")

    def test_zero_pads_single_digit_fields(self):
        dt = datetime(2026, 1, 5, 3, 4, 9, tzinfo=timezone.utc)
        self.assertEqual(_format_timestamp(dt), "2026-01-05T03:04:09.000000Z")


# ---------------------------------------------------------------------------
# fetch_events
# ---------------------------------------------------------------------------


class TestFetchEvents(unittest.TestCase):
    def setUp(self):
        self.window_start = datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc)
        self.url = "https://idp.example.com"
        self.token = "test-bearer-token"

    @patch("urllib.request.urlopen")
    def test_single_page_result(self, mock_urlopen):
        events = [_make_event("2026-04-21T15:05:00.000000Z")]
        mock_urlopen.return_value = _mock_urlopen({"events": events})

        result = fetch_events(self.url, self.token, self.window_start)

        self.assertEqual(result, events)
        self.assertEqual(mock_urlopen.call_count, 1)

    @patch("urllib.request.urlopen")
    def test_bearer_token_in_header(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen({"events": []})

        fetch_events(self.url, self.token, self.window_start)

        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.get_header("Authorization"), f"Bearer {self.token}")

    @patch("urllib.request.urlopen")
    def test_content_type_header(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen({"events": []})

        fetch_events(self.url, self.token, self.window_start)

        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.get_header("Content-type"), "application/json")

    @patch("urllib.request.urlopen")
    def test_from_param_in_request_body(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen({"events": []})

        fetch_events(self.url, self.token, self.window_start)

        req = mock_urlopen.call_args[0][0]
        body = json.loads(req.data.decode())
        self.assertEqual(body["from"], "2026-04-21T15:00:00.000000Z")

    @patch("urllib.request.urlopen")
    def test_trailing_slash_stripped_from_url(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen({"events": []})

        fetch_events("https://idp.example.com/", self.token, self.window_start)

        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.full_url, "https://idp.example.com/events/_search")

    @patch("urllib.request.urlopen")
    def test_empty_response(self, mock_urlopen):
        mock_urlopen.return_value = _mock_urlopen({"events": []})

        result = fetch_events(self.url, self.token, self.window_start)

        self.assertEqual(result, [])


# ---------------------------------------------------------------------------
# save_to_s3
# ---------------------------------------------------------------------------


class TestSaveToS3(unittest.TestCase):
    @patch("boto3.client")
    def test_puts_object_with_correct_bucket_and_key(self, mock_boto3_client):
        mock_s3 = MagicMock()
        mock_boto3_client.return_value = mock_s3

        events = [_make_event("2026-04-21T15:05:00.000000Z")]
        save_to_s3("my-bucket", "events/2026/04/21/15-00-00.json", events)

        mock_boto3_client.assert_called_once_with("s3")
        call_kwargs = mock_s3.put_object.call_args[1]
        self.assertEqual(call_kwargs["Bucket"], "my-bucket")
        self.assertEqual(call_kwargs["Key"], "events/2026/04/21/15-00-00.json")

    @patch("boto3.client")
    def test_body_contains_events_array(self, mock_boto3_client):
        mock_s3 = MagicMock()
        mock_boto3_client.return_value = mock_s3

        events = [_make_event("2026-04-21T15:05:00.000000Z")]
        save_to_s3("my-bucket", "some/key.json", events)

        call_kwargs = mock_s3.put_object.call_args[1]
        body = json.loads(call_kwargs["Body"])
        self.assertEqual(body["events"], events)

    @patch("boto3.client")
    def test_content_type_is_json(self, mock_boto3_client):
        mock_s3 = MagicMock()
        mock_boto3_client.return_value = mock_s3

        save_to_s3("my-bucket", "key.json", [])

        call_kwargs = mock_s3.put_object.call_args[1]
        self.assertEqual(call_kwargs["ContentType"], "application/json")

    @patch("boto3.client")
    def test_empty_event_list_saved(self, mock_boto3_client):
        mock_s3 = MagicMock()
        mock_boto3_client.return_value = mock_s3

        save_to_s3("my-bucket", "key.json", [])

        call_kwargs = mock_s3.put_object.call_args[1]
        body = json.loads(call_kwargs["Body"])
        self.assertEqual(body["events"], [])


# ---------------------------------------------------------------------------
# _load_bearer_token
# ---------------------------------------------------------------------------


class TestLoadBearerToken(unittest.TestCase):
    def setUp(self):
        main._bearer_token = None

    def tearDown(self):
        main._bearer_token = None

    @patch("boto3.client")
    def test_reads_from_ssm_with_decryption(self, mock_boto3_client):
        mock_ssm = MagicMock()
        mock_ssm.get_parameter.return_value = {
            "Parameter": {"Value": "super-secret-token"}
        }
        mock_boto3_client.return_value = mock_ssm

        from main import _load_bearer_token

        result = _load_bearer_token()

        self.assertEqual(result, "super-secret-token")
        mock_ssm.get_parameter.assert_called_once_with(
            Name="/platform/idp/bearer-token", WithDecryption=True
        )

    @patch("boto3.client")
    def test_token_cached_after_first_call(self, mock_boto3_client):
        mock_ssm = MagicMock()
        mock_ssm.get_parameter.return_value = {"Parameter": {"Value": "cached-token"}}
        mock_boto3_client.return_value = mock_ssm

        from main import _load_bearer_token

        _load_bearer_token()
        _load_bearer_token()
        _load_bearer_token()

        # SSM should only be called once regardless of how many times we call the helper
        self.assertEqual(mock_ssm.get_parameter.call_count, 1)

    @patch("boto3.client")
    def test_returns_cached_value_on_subsequent_calls(self, mock_boto3_client):
        mock_ssm = MagicMock()
        mock_ssm.get_parameter.return_value = {"Parameter": {"Value": "tok1"}}
        mock_boto3_client.return_value = mock_ssm

        from main import _load_bearer_token

        first = _load_bearer_token()
        second = _load_bearer_token()

        self.assertEqual(first, second)


# ---------------------------------------------------------------------------
# handler
# ---------------------------------------------------------------------------


class TestLambdaHandler(unittest.TestCase):
    def setUp(self):
        main._bearer_token = None

    def tearDown(self):
        main._bearer_token = None

    @patch("main.save_to_s3")
    @patch("main.fetch_events")
    @patch("main._load_bearer_token", return_value="handler-token")
    @patch("main._get_now")
    def test_returns_200_status(self, mock_now, _mock_token, mock_fetch, mock_save):
        mock_fetch.return_value = []
        mock_now.return_value = datetime(2026, 4, 21, 15, 22, 0, tzinfo=timezone.utc)

        result = handler({}, None)

        self.assertEqual(result["statusCode"], 200)

    @patch("main.save_to_s3")
    @patch("main.fetch_events")
    @patch("main._load_bearer_token", return_value="handler-token")
    @patch("main._get_now")
    def test_events_count_matches_fetched_events(
        self, mock_now, _mock_token, mock_fetch, mock_save
    ):
        mock_now.return_value = datetime(2026, 4, 21, 15, 22, 0, tzinfo=timezone.utc)
        mock_fetch.return_value = [
            _make_event("2026-04-21T15:07:00.000000Z", sequence=1),
            _make_event("2026-04-21T14:59:00.000000Z", sequence=2),
            _make_event("2026-04-21T15:16:00.000000Z", sequence=3),
        ]

        result = handler({}, None)

        self.assertEqual(result["events_count"], 3)

    @patch("main.save_to_s3")
    @patch("main.fetch_events")
    @patch("main._load_bearer_token", return_value="handler-token")
    @patch("main._get_now")
    def test_s3_key_uses_window_start(
        self, mock_now, _mock_token, mock_fetch, mock_save
    ):
        mock_now.return_value = datetime(2026, 4, 21, 15, 22, 0, tzinfo=timezone.utc)
        mock_fetch.return_value = []

        result = handler({}, None)

        self.assertEqual(result["s3_key"], "events/2026/04/21/15-00-00.json")
        mock_save.assert_called_once_with(
            main.S3_BUCKET,
            "events/2026/04/21/15-00-00.json",
            [],
        )

    @patch("main.save_to_s3")
    @patch("main.fetch_events")
    @patch("main._load_bearer_token", return_value="handler-token")
    @patch("main._get_now")
    def test_response_contains_window_boundaries(
        self, mock_now, _mock_token, mock_fetch, mock_save
    ):
        mock_now.return_value = datetime(2026, 4, 21, 15, 22, 0, tzinfo=timezone.utc)
        mock_fetch.return_value = []

        result = handler({}, None)

        self.assertIn("window_start", result)
        self.assertIn("window_end", result)
        self.assertIn("15:00:00", result["window_start"])
        self.assertIn("15:15:00", result["window_end"])

    @patch("main.save_to_s3")
    @patch("main.fetch_events")
    @patch("main._load_bearer_token", return_value="handler-token")
    @patch("main._get_now")
    def test_fetch_called_with_token_and_window_start(
        self, mock_now, _mock_token, mock_fetch, mock_save
    ):
        mock_now.return_value = datetime(2026, 4, 21, 15, 22, 0, tzinfo=timezone.utc)
        mock_fetch.return_value = []

        handler({}, None)

        expected_window_start = datetime(2026, 4, 21, 15, 0, 0, tzinfo=timezone.utc)
        mock_fetch.assert_called_once_with(
            main.ZITADEL_URL, "handler-token", expected_window_start
        )


if __name__ == "__main__":
    unittest.main()
