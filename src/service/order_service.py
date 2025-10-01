from random import random
from time import sleep

from src.data.sample_data import sample_orders


def get_order(order_id):
    """
    Fetches an order by its ID.
    """
    # Simulate fetching an order from a database
    sleep(0.5 + (0.1 * int(random() * 5)))  # sleep for 50-100 ms
    for order in sample_orders:
        if order.id == order_id:
            return order
    return None


def get_orders():
    """
    Fetches all orders.
    """
    sleep(0.5 + (0.1 * int(random() * 5)))  # sleep for 50-100 ms
    # Simulate fetching all orders from a database
    return sample_orders
