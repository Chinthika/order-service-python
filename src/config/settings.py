"""Application runtime configuration powered by environment variables."""
import os
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Centralised configuration for the order service application."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "Order Service API"
    environment: str = os.getenv("ENVIRONMENT", "local")
    log_level: str = "INFO"

    enable_metrics: bool = True

    secrets_manager_enabled: bool = False
    aws_region: Optional[str] = None
    aws_secret_name: Optional[str] = None
    aws_profile: Optional[str] = None

    @property
    def should_use_secrets_manager(self) -> bool:
        """Indicate whether AWS Secrets Manager should be used for runtime secrets."""
        return self.secrets_manager_enabled and bool(self.aws_secret_name)


@lru_cache
def get_settings() -> Settings:
    """Return a cached settings instance to avoid repeated environment parsing."""

    return Settings()
