import os

from locust import HttpUser, task, between

# Simple Locust test aimed at prod
# Usage examples:
#   GUI:     locust -f api_load_test.py --host https://prod.chinthika-jayani.click
#   Headless: locust -f api_load_test.py --headless -u 50 -r 5 -t 5m \
#             --host https://prod.chinthika-jayani.click
# You can also set LOCUST_HOST env var instead of --host.

DEFAULT_HOST = "https://prod.chinthika-jayani.click"


class APIUser(HttpUser):
    # If no --host/LOCUST_HOST is provided, fall back to the prod URL
    host = os.getenv("LOCUST_HOST", DEFAULT_HOST)

    # Pause between tasks to simulate real users
    wait_time = between(0.5, 2.0)

    def on_start(self):
        # Example: bearer token from env (if your API needs it)
        token = os.getenv("API_BEARER_TOKEN")
        self.common_headers = {"Accept": "application/json"}
        if token:
            self.common_headers["Authorization"] = f"Bearer {token}"

    # --- Basic health check (fast, always-on) ---
    @task(3)
    def health(self):
        self.client.get("/health", headers=self.common_headers, name="GET /health")

    # --- Example business endpoint: list items/orders ---
    @task(2)
    def list_orders(self):
        # Change the path to your real endpoint if different
        self.client.get("/orders", headers=self.common_headers, name="GET /api/orders")

    # --- Example read-by-id with a small id range ---
    @task(1)
    def get_order_by_id(self):
        order_id = 1 # Change as needed or randomize within a valid range
        self.client.get(f"/orders/{order_id}", headers=self.common_headers, name="GET /api/orders/{id}")
