# test app.py
from fastapi.testclient import TestClient

from src.app import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the Order Service API - local"}


def test_get_orders():
    response = client.get("/orders")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
    assert len(response.json()) > 0


def test_get_order_by_id():
    response = client.get("/orders/1")
    assert response.status_code == 200
    assert response.json()["id"] == "1"
    assert response.json()["customer_name"] == "John Doe"
    assert response.json()["status"] == "DELIVERED"

    # Test non-existing order
    response = client.get("/orders/999")
    assert response.status_code == 404


def test_metrics_endpoint_exposed():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
