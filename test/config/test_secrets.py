import pytest

from src.config.secrets import AwsSecretsManager, SecretRetrievalError, load_runtime_secrets
from src.config.settings import Settings


class DummySecretsClient:
    def __init__(self, payload):
        self._payload = payload

    def get_secret_value(self, SecretId: str):  # noqa: N803 - AWS uses camelCase keys
        return self._payload


def test_fetch_secret_returns_json_payload():
    client = DummySecretsClient({"SecretString": "{\"api_key\": \"abc\"}"})
    manager = AwsSecretsManager(region_name="us-east-1", client=client)

    secret = manager.fetch_secret("dummy")

    assert secret == {"api_key": "abc"}


def test_fetch_secret_rejects_missing_payload():
    client = DummySecretsClient({})
    manager = AwsSecretsManager(region_name="us-east-1", client=client)

    with pytest.raises(SecretRetrievalError):
        manager.fetch_secret("dummy")


def test_load_runtime_secrets_respects_disabled_flag():
    settings = Settings(secrets_manager_enabled=False)
    assert load_runtime_secrets(settings) == {}
