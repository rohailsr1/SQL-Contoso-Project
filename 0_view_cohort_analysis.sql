

CREATE VIEW cohort_analysis AS 

WITH customer_revenue AS (
         SELECT s.customerkey,
            s.orderdate,
            sum(s.netprice * s.quantity::double precision / s.exchangerate) AS total_net_revenue,
            count(s.orderkey) AS num_orders,
            MAX(c.countryfull) AS countryfull,
            MAX(c.age) AS age,
            MAX(c.givenname) AS givenname,
            MAX(c.surname) AS surname
           FROM sales s
             LEFT JOIN customer c ON s.customerkey = c.customerkey
          GROUP BY 
          		s.customerkey, 
          		s.orderdate
        )
 SELECT 
 	customerkey,
    orderdate,
    total_net_revenue,
    num_orders,
    countryfull,
    age,
    CONCAT (givenname, ' ', surname) AS cleaned_name,
    min(orderdate) OVER (PARTITION BY customerkey) AS first_purchase_date,
    EXTRACT(year FROM min(orderdate) OVER (PARTITION BY customerkey)) AS cohort_year
   FROM customer_revenue cr;