ALTER TABLE product
ADD COLUMN price DOUBLE PRECISION;

UPDATE product p
SET price = pi.price
FROM product_info pi
WHERE p.id = pi.product_id;

ALTER TABLE orders
ADD COLUMN date_created DATE DEFAULT CURRENT_DATE;

UPDATE orders o
SET date_created = od.date_created
FROM orders_date od
WHERE o.id = od.order_id;

DROP TABLE product_info;
DROP TABLE orders_date;

ALTER TABLE order_product
ADD CONSTRAINT fk_order
FOREIGN KEY (order_id)
REFERENCES orders(id);

ALTER TABLE order_product
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES product(id);