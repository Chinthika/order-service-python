# test order_service.py
from src.model.order import OrderStatus
from src.service.order_service import get_order, get_orders


# test get_order function
def test_get_order():
    # Test fetching an existing order
    order = get_order("1")
    assert order is not None
    assert order.id == "1"
    assert order.customer_name == "John Doe"
    assert order.status == OrderStatus.DELIVERED

    # Test fetching a non-existing order
    order = get_order("999")
    assert order is None


def test_get_orders():
    # Test fetching all orders
    orders = get_orders()
    assert len(orders) > 0
    assert orders[0].id == "1"
    assert orders[1].customer_name == "Jane Smith"
    assert orders[2].status == OrderStatus.PENDING
