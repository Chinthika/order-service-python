"""Helpers for retrieving runtime secrets from AWS Secrets Manager."""

from __future__ import annotations

import base64
import json
import logging
from typing import Any, Dict, Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from .settings import Settings

logger = logging.getLogger(__name__)


class SecretRetrievalError(RuntimeError):
    """Raised when secret material cannot be loaded."""


class AwsSecretsManager:
    """Simple wrapper around the AWS Secrets Manager API."""

    def __init__(
        self,
        region_name: Optional[str],
        profile_name: Optional[str] = None,
        client: Optional[Any] = None,
    ) -> None:
        session_kwargs: Dict[str, Any] = {}
        if profile_name:
            session_kwargs["profile_name"] = profile_name

        if client is not None:
            self._client = client
        else:
            session = boto3.session.Session(**session_kwargs)
            self._client = session.client("secretsmanager", region_name=region_name)

    def fetch_secret(self, secret_id: str) -> Dict[str, Any]:
        """Fetch and decode a secret's payload as a dictionary."""

        try:
            response = self._client.get_secret_value(SecretId=secret_id)
        except (ClientError, BotoCoreError) as exc:  # pragma: no cover - network errors mocked in tests
            raise SecretRetrievalError(f"Unable to download secret '{secret_id}'") from exc

        payload: Optional[str] = response.get("SecretString")
        if payload is None and "SecretBinary" in response:
            payload = base64.b64decode(response["SecretBinary"]).decode("utf-8")

        if payload is None:
            raise SecretRetrievalError(f"Secret '{secret_id}' contains no payload")

        try:
            decoded = json.loads(payload)
            if not isinstance(decoded, dict):
                raise ValueError("Secret payload must be a JSON object")
            return decoded
        except (json.JSONDecodeError, ValueError) as exc:
            raise SecretRetrievalError("Secret payload must be valid JSON object") from exc


def load_runtime_secrets(settings: Settings) -> Dict[str, Any]:
    """Load runtime secrets based on application settings."""

    if not settings.should_use_secrets_manager:
        logger.info("Secrets Manager disabled; skipping fetch")
        return {}

    manager = AwsSecretsManager(
        region_name=settings.aws_region,
        profile_name=settings.aws_profile,
    )

    try:
        secrets = manager.fetch_secret(settings.aws_secret_name)  # type: ignore[arg-type]
        logger.info("Loaded %s keys from AWS Secrets Manager", len(secrets))
        return secrets
    except SecretRetrievalError as exc:
        logger.error("Failed to load secrets: %s", exc)
        raise
