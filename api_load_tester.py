import os

from locust import HttpUser, task, between

# Simple Locust test aimed at prod
# Usage examples:
#   GUI:     locust -f api_load_tester.py --host https://prod.chinthika-jayani.click
#   Headless: locust -f api_load_tester.py --headless -u 50 -r 5 -t 5m \
#             --host https://prod.chinthika-jayani.click
# You can also set LOCUST_HOST env var instead of --host.

DEFAULT_HOST = "https://prod.chinthika-jayani.click"


class APIUser(HttpUser):
    host = os.getenv("LOCUST_HOST", DEFAULT_HOST)

    wait_time = between(0.5, 2.0)

    def on_start(self):
        token = os.getenv("API_BEARER_TOKEN")
        self.common_headers = {"Accept": "application/json"}
        if token:
            self.common_headers["Authorization"] = f"Bearer {token}"

    # @task(4)
    # def get_order_by_wrong_id(self):
    #     order_id = 11  # Wrong order ID
    #     self.client.get(f"/orders/{order_id}", headers=self.common_headers, name="GET /api/orders/{id}")

    @task(3)
    def health(self):
        self.client.get("/health", headers=self.common_headers, name="GET /health")

    @task(2)
    def list_orders(self):
        # Change the path to your real endpoint if different
        self.client.get("/orders", headers=self.common_headers, name="GET /api/orders")

    @task(1)
    def get_order_by_id(self):
        order_id = 1  # Change as needed
        self.client.get(f"/orders/{order_id}", headers=self.common_headers, name="GET /api/orders/{id}")
