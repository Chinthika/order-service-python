from datetime import datetime, timedelta

from src.model.order import Order, OrderStatus

# Sample orders data
sample_orders = [
    Order(
        id="1",
        customer_name="John Doe",
        order_date=datetime.now() - timedelta(days=5),
        total_amount=129.99,
        status=OrderStatus.DELIVERED,
        items=[
            {"product_id": 1, "name": "Laptop Stand", "quantity": 1, "price": 29.99},
            {"product_id": 2, "name": "Wireless Mouse", "quantity": 1, "price": 100.00}
        ],
        shipping_address="123 Main St, New York, NY 10001",
        tracking_number="1Z999AA1234567890"
    ),
    Order(
        id="2",
        customer_name="Jane Smith",
        order_date=datetime.now() - timedelta(days=1),
        total_amount=75.50,
        status=OrderStatus.PROCESSING,
        items=[
            {"product_id": 3, "name": "Mechanical Keyboard", "quantity": 1, "price": 75.50}
        ],
        shipping_address="456 Oak Ave, Los Angeles, CA 90001"
    ),
    Order(
        id="3",
        customer_name="Bob Wilson",
        order_date=datetime.now() - timedelta(hours=2),
        total_amount=199.97,
        status=OrderStatus.PENDING,
        items=[
            {"product_id": 4, "name": "Monitor", "quantity": 1, "price": 199.97}
        ],
        shipping_address="789 Pine Rd, Chicago, IL 60601"
    )
]
