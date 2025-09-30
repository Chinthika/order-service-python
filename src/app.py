"""FastAPI application entry point with observability hooks."""
import newrelic.agent

newrelic.agent.initialize('newrelic.ini')

from fastapi import FastAPI, HTTPException

from src.config import get_settings
from src.service.order_service import get_order as service_get_order
from src.service.order_service import get_orders as service_get_orders
from src.utils import create_response

settings = get_settings()
app = FastAPI(title=settings.app_name)
if settings.environment is not "local":
    app = newrelic.agent.register_application()(app)


@app.get("/")
async def root() -> dict:
    return {"message": f"Welcome to the Order Service API - {settings.environment}"}


@app.get("/health")
async def health() -> tuple[dict, int]:
    return {"status": "OK"}, 200


@app.get("/orders")
async def get_orders():
    return create_response(service_get_orders())


@app.get("/orders/{order_id}")
async def get_order_by_id(order_id: str):
    # Fetch an order by its ID

    # return 404 if not found
    order = service_get_order(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")

    # return 200 if found
    return order
