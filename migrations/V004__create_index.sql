DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_date_created;

CREATE INDEX idx_orders_status_date
ON orders(status, date_created);

CREATE INDEX idx_order_product_order_id
ON order_product(order_id);

CREATE INDEX idx_order_product_product_id
ON order_product(product_id);