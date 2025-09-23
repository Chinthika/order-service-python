from src.data.sample_data import sample_orders


def get_order(order_id):
    """
    Fetches an order by its ID.
    """
    # Simulate fetching an order from a database
    for order in sample_orders:
        if order.id == order_id:
            return order
    return None


def get_orders():
    """
    Fetches all orders.
    """
    # Simulate fetching all orders from a database
    return sample_orders
