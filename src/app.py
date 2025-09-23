"""FastAPI application entry point with observability hooks."""

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator

from src.config import get_settings
from src.service.order_service import get_order as service_get_order
from src.service.order_service import get_orders as service_get_orders
from src.utils import create_response


settings = get_settings()
app = FastAPI(title=settings.app_name)


def _configure_metrics(instrumentation_app: FastAPI) -> None:
    """Register Prometheus instrumentation on the FastAPI app if enabled."""

    if not settings.enable_metrics:
        return

    # Avoid re-registering the metrics endpoint in testing scenarios.
    if getattr(instrumentation_app.state, "metrics_configured", False):
        return

    Instrumentator().instrument(instrumentation_app).expose(
        instrumentation_app,
        endpoint=settings.metrics_endpoint,
        include_in_schema=False,
    )
    instrumentation_app.state.metrics_configured = True


@app.on_event("startup")
async def startup_event() -> None:
    _configure_metrics(app)


@app.get("/")
async def root() -> dict:
    return {"message": "Welcome to the Order Service API"}


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


_configure_metrics(app)
