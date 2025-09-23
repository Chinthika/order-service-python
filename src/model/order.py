from datetime import datetime
from typing import List, Optional
from dataclasses import dataclass
from enum import Enum


class OrderStatus(Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"


@dataclass
class Order:
    id: str
    customer_name: str
    order_date: datetime
    total_amount: float
    status: OrderStatus
    items: List[dict]
    shipping_address: str
    tracking_number: Optional[str] = None
