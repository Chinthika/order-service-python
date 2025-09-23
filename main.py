"""Application bootstrapper for local development and production runtime."""

from __future__ import annotations

import logging
import os

import uvicorn

from src.app import app
from src.config import Settings, get_settings
from src.config.secrets import SecretRetrievalError, load_runtime_secrets


def _prepare_runtime_environment() -> Settings:
    """Initialise logging, load secrets, and return the settings object."""

    settings = get_settings()
    logging.basicConfig(level=settings.log_level)

    try:
        secrets = load_runtime_secrets(settings)
    except SecretRetrievalError:
        # Fail fast if secrets are required but unavailable.
        raise

    for key, value in secrets.items():
        os.environ.setdefault(key, str(value))

    return settings


if __name__ == "__main__":
    _prepare_runtime_environment()

    uvicorn.run(app, host="0.0.0.0", port=8000)
