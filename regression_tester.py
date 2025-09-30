import os

import requests

BASE_URL = os.getenv("REGRESSION_BASE_URL", "https://staging.chinthika-jayani.click")
ENVIRONMENT = os.getenv("ENVIRONMENT", "staging")


def test_root_endpoint():
    resp = requests.get(f"{BASE_URL}/")
    assert resp.status_code == 200
    body = resp.json()
    assert "message" in body
    assert f"Welcome to the Order Service API - {ENVIRONMENT}" in body["message"]


def test_health_endpoint():
    resp = requests.get(f"{BASE_URL}/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body == [{"status": "OK"}, 200]


def test_orders_endpoint():
    resp = requests.get(f"{BASE_URL}/orders")
    assert resp.status_code == 200
    body = resp.json()
    assert isinstance(body, list)
    assert len(body) == 3
    assert body[0]["id"] == "1"
    assert body[1]["customer_name"] == "Jane Smith"
    assert body[2]["status"] == "PENDING"


def test_order_by_id():
    resp = requests.get(f"{BASE_URL}/orders/1")
    assert resp.status_code == 200
    body = resp.json()
    assert body["id"] == "1"
    assert body["customer_name"] == "John Doe"
    assert body["status"] == "DELIVERED"


def test_order_not_found():
    resp = requests.get(f"{BASE_URL}/orders/nonexistent-id")
    assert resp.status_code == 404
    body = resp.json()
    assert body["detail"] == "Order not found"
