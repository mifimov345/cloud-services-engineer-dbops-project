# dbops-project Исходный репозиторий для выполнения проекта дисциплины "DBOps"
CREATE DATABASE store;
CREATE USER store_user WITH PASSWORD 'store_password';
GRANT ALL PRIVILEGES ON DATABASE store TO store_user; 
\c store
GRANT ALL ON SCHEMA public TO store_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO store_user;

### До индексов
```
SELECT o.date_created, SUM(op.quantity) FROM orders AS o JOIN order_product AS op ON o.id = op.order_id WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY' GROUP BY o.date_created;
 date_created |  sum
--------------+--------
 2026-03-09   | 940124
 2026-03-10   | 943154
 2026-03-11   | 950703
 2026-03-12   | 660226
(4 rows)

Time: 4088.799 ms (00:04.089)
EXPLAIN ANALYZE SELECT o.date_created, SUM(op.quantity) FROM orders AS o JOIN order_product AS op ON o.id = op.order_id WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY' GROUP BY o.date_created;
Time: 2737.387 ms (00:02.737)
EXPLAIN ANALYZE SELECT o.date_created, SUM(op.quantity) FROM orders AS o JOIN order_product AS op ON o.id = op.order_id WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY' GROUP BY o.date_created;
                                                                                    QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=190070.14..190093.19 rows=91 width=12) (actual time=1811.484..1814.745 rows=4 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=190070.14..190091.37 rows=182 width=12) (actual time=1811.466..1814.725 rows=12 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=189070.11..189070.34 rows=91 width=12) (actual time=1777.147..1777.151 rows=4 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=189066.24..189067.15 rows=91 width=12) (actual time=1777.118..1777.123 rows=4 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=72477.61..188776.78 rows=57893 width=8) (actual time=377.529..1762.278 rows=45742 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.67 rows=4166667 width=12) (actual time=0.031..454.003 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=71753.95..71753.95 rows=57893 width=12) (actual time=376.503..376.505 rows=45742 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 8544kB
                                 ->  Parallel Bitmap Heap Scan on orders o  (cost=4581.17..71753.95 rows=57893 width=12) (actual time=43.393..355.093 rows=45742 loops=3)
                                       Recheck Cond: (date_created > (now() - '7 days'::interval))
                                       Filter: ((status)::text = 'shipped'::text)
                                       Rows Removed by Filter: 91464
                                       Heap Blocks: exact=26498
                                       ->  Bitmap Index Scan on idx_orders_date_created  (cost=0.00..4546.44 rows=417333 width=0) (actual time=41.604..41.604 rows=411619 loops=1)
                                             Index Cond: (date_created > (now() - '7 days'::interval))
 Planning Time: 0.492 ms
 JIT:
   Functions: 63
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 3.373 ms, Inlining 0.000 ms, Optimization 2.338 ms, Emission 43.888 ms, Total 49.599 ms
 Execution Time: 1816.000 ms
```


### После индексов

```
SELECT o.date_created, SUM(op.quantity) FROM orders AS o JOIN order_product AS op ON o.id = op.order_id WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY' GROUP BY o.date_created;
 date_created |  sum
--------------+--------
 2026-03-09   | 938325
 2026-03-10   | 938316
 2026-03-11   | 944554
 2026-03-12   | 947506
 2026-03-13   | 942145
 2026-03-14   | 936195
 2026-03-15   | 545865
(7 rows)

Time: 1570.491 ms (00:01.570)
store=> EXPLAIN ANALYZE SELECT o.date_created, SUM(op.quantity) FROM orders AS o JOIN order_product AS op ON o.id = op.order_id WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY' GROUP BY o.date_created;
                                                                                    QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=188170.80..188193.86 rows=91 width=12) (actual time=2689.644..2703.993 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=188170.80..188192.04 rows=182 width=12) (actual time=2689.628..2703.973 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=187170.78..187171.01 rows=91 width=12) (actual time=2662.132..2662.136 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=187166.91..187167.82 rows=91 width=12) (actual time=2662.107..2662.112 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=70357.64..186657.42 rows=101898 width=8) (actual time=807.478..2638.146 rows=81186 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105362.15 rows=4166715 width=12) (actual time=0.031..412.771 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=69083.96..69083.96 rows=101895 width=12) (actual time=804.528..804.529 rows=81186 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 13536kB
                                 ->  Parallel Bitmap Heap Scan on orders o  (cost=3351.06..69083.96 rows=101895 width=12) (actual time=41.630..769.779 rows=81186 loops=3)
                                       Recheck Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Heap Blocks: exact=28788
                                       ->  Bitmap Index Scan on idx_orders_status_date  (cost=0.00..3289.92 rows=244548 width=0) (actual time=38.476..38.477 rows=243559 loops=1)
                                             Index Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
 Planning Time: 2.797 ms
 JIT:
   Functions: 57
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 2.441 ms, Inlining 0.000 ms, Optimization 1.639 ms, Emission 32.928 ms, Total 37.008 ms
 Execution Time: 2705.127 ms
```

### Вывод
После добавления индексов время запроса сократилось с 4088.799 ms до 1570.491 ms
