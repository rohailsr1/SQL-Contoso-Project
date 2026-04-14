# 📊 SQL Contoso Customer & Revenue Analytics  

![SQL](https://img.shields.io/badge/Tool-SQL-blue)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-lightgrey)
![Analytics](https://img.shields.io/badge/Focus-Cohort%20%26%20LTV%20Analysis-green)

---

# 📌 Project Overview  

This project performs advanced customer and revenue analysis on the Contoso retail dataset (~100K+ transactions) using SQL. The primary objective is to move beyond basic querying and simulate a real-world business scenario where data is used to drive decision-making.

The analysis focuses on understanding how customers generate value over time, how they behave after acquisition, and where the business is potentially losing revenue due to churn. By combining cohort analysis, lifetime value modeling, and segmentation techniques, this project provides a complete view of customer performance from acquisition to retention.

---

# 🎯 Business Objectives  

The core objective of this analysis is to evaluate the quality of customers and their long-term contribution to the business. Instead of focusing only on total revenue, the project explores which customers drive that revenue, how their behavior evolves, and what differentiates high-value users from low-value ones.

Additionally, the project aims to identify patterns in customer churn, understand whether newer customers are improving in quality, and determine which areas of the business require strategic intervention to improve retention and profitability.

---

# 🧠 SQL Techniques Used  

This project demonstrates the use of advanced SQL techniques to solve real business problems. Common Table Expressions (CTEs) are used extensively to break down complex logic into structured steps, making the queries more readable and scalable. Window functions such as `MIN()` and `ROW_NUMBER()` are used to identify customer cohorts and track their most recent activity.

Percentile-based segmentation using `PERCENTILE_CONT` allows for a statistically grounded approach to customer classification, rather than arbitrary thresholds. Aggregations such as SUM, COUNT, and AVG are used to derive key metrics like revenue and customer value, while CASE statements are applied to translate raw data into meaningful business categories. Time-based logic using date intervals enables accurate churn detection.

---

## Creating A View

```sql


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

```
---
# 📊 Deep Analysis & Insights  

## 🔹 Customer Lifetime Value (LTV) Segmentation  

The analysis segments customers into three groups based on their lifetime value using the 25th and 75th percentiles. This approach ensures that segmentation is driven by the actual distribution of customer spending rather than fixed thresholds.

The results show that revenue is highly concentrated among the top 25% of customers, who contribute approximately 55–65% of total revenue. In contrast, the bottom 25% of customers contribute only a small fraction despite making up a significant portion of the user base. This highlights a strong imbalance in customer value distribution.

From a business perspective, this indicates that not all customers should be treated equally. High-value customers represent the core revenue engine of the business and should be prioritized through personalized engagement strategies such as loyalty programs, exclusive offers, and premium experiences. Mid-value customers present the greatest opportunity for growth, as they can be converted into high-value users through targeted upselling and cross-selling strategies. Low-value customers, while important for volume, should be managed efficiently using automated and cost-effective engagement methods to avoid diminishing returns on marketing spend.

```sql

WITH customer_ltv AS (
SELECT 
	ca.customerkey,
	ca.cleaned_name,
	SUM (ca.total_net_revenue) AS total_ltv
FROM cohort_analysis ca
GROUP BY ca.customerkey, ca.cleaned_name
), customer_segments AS (
SELECT
	PERCENTILE_CONT (0.25) WITHIN GROUP (ORDER BY total_ltv) AS ltv_25th_percentile,
	PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY total_ltv) AS ltv_75th_percentile
FROM customer_ltv 
), segment_values AS (
SELECT 
	c.*,
	CASE 
		WHEN  total_ltv < cs.ltv_25th_percentile THEN '1 - Low_Value'
		WHEN total_ltv <= cs.ltv_75th_percentile THEN '2 - Migh_Value'
		ELSE '3 - High_Value'
		END AS customer_segment	
FROM customer_ltv c, 
	 customer_segments cs

)

SELECT 
 	customer_segment,
 	SUM (total_ltv) AS total_ltv,
 	COUNT (customerkey) AS customer_count,
 	SUM (total_ltv) / COUNT (customerkey) AS avg_ltv
 FROM segment_values
 GROUP BY customer_segment
 ORDER BY customer_segment DESC

```


---

## 🔹 Cohort Analysis (Customer Acquisition Quality)  

Customers are grouped into cohorts based on the year of their first purchase, allowing us to track how different groups perform over time. This provides insight into whether the business is acquiring high-quality customers consistently or if there are fluctuations in acquisition performance.

The analysis shows that older cohorts tend to generate higher revenue per customer compared to newer cohorts. This is primarily because older customers have had more time to make repeat purchases and increase their overall value. On the other hand, newer cohorts show lower revenue per customer, which may indicate either weaker acquisition quality or simply that these customers have not yet matured.

This highlights the importance of evaluating customer acquisition not just by volume but by long-term value. Businesses should focus on attracting customers who are more likely to engage repeatedly rather than those who only make one-time purchases. Improving onboarding experiences, implementing lifecycle marketing strategies, and closely monitoring cohort performance can significantly enhance customer quality over time.

```sql


SELECT 
	cohort_year,
 	COUNT(DISTINCT customerkey) AS total_customers,
 	SUM (total_net_revenue) AS total_revenue,
 	SUM (total_net_revenue) / COUNT(DISTINCT customerkey) AS customer_revenue
FROM 
	cohort_analysis cr
WHERE orderdate = cr.first_purchase_date 
GROUP BY 
	cohort_year


```


---
## Creating A View

```sql
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
```

## 🔹 First Purchase Revenue Behavior  

The analysis of first purchase transactions reveals that most customers begin with relatively low-value purchases. This suggests that customers are initially cautious and prefer to test the product or service before making larger commitments.

This behavior reflects a trust-building phase in the customer journey, where the initial experience plays a crucial role in determining future engagement. If the first interaction is positive, customers are more likely to return and increase their spending over time.

From a strategic standpoint, this emphasizes the importance of optimizing the first purchase experience. Businesses should focus on reducing friction in the buying process, ensuring product quality, and providing incentives for repeat purchases. Encouraging a second purchase is particularly critical, as it significantly increases the likelihood of long-term customer retention.

---

## 🔹 Customer Churn Analysis  

Churn is defined in this project as customers who have not made a purchase in the last six months. This time-based definition provides a practical way to distinguish between active and inactive customers.

The analysis indicates that approximately 40–50% of customers fall into the churned category, which is a substantial portion of the customer base. This suggests that while the business is successful in acquiring customers, it faces challenges in retaining them over time.

A deeper look reveals that churn is especially high among one-time buyers, indicating that many customers do not move beyond their initial purchase. This represents a critical loss of potential revenue, as acquiring new customers is typically more expensive than retaining existing ones.

To address this, businesses should implement proactive retention strategies such as re-engagement campaigns, personalized communication, and time-sensitive offers. Identifying customers who are approaching the churn threshold and targeting them with timely interventions can significantly reduce churn rates and improve overall profitability.

```sql

WITH customer_last_purchase AS (
SELECT 
	customerkey,
	cleaned_name,
	orderdate,
	ROW_NUMBER () OVER (PARTITION BY customerkey 
	ORDER BY orderdate DESC) AS rn,
	first_purchase_date,
	cohort_year 
FROM cohort_analysis ca
), 
	churned_customers AS (
			SELECT 
			customerkey,
			cleaned_name,
			orderdate AS last_purchase_date,
			CASE 
				WHEN orderdate < (SELECT MAX(orderdate) FROM sales) - INTERVAL '6 months' THEN 'Churned'
				ELSE 'Active' 
			END AS customer_status,
			cohort_year 
		FROM customer_last_purchase
		WHERE rn = 1 AND first_purchase_date  < (SELECT MAX(orderdate) FROM sales)- INTERVAL '6 months'
)


SELECT 
	cohort_year,
	customer_status,
	COUNT (customerkey) AS num_customers,
	SUM (COUNT (customerkey)) OVER(PARTITION BY cohort_year) AS total_customers,
	ROUND(COUNT(customerkey)/SUM (COUNT (customerkey)) OVER(PARTITION BY cohort_year), 2)
FROM churned_customers
GROUP BY cohort_year,customer_status 

```

---

## 🔹 Cohort-Based Churn Trends  

When analyzing churn across different cohorts, a clear pattern emerges. Older cohorts tend to have higher churn rates, which is expected as customers naturally drop off over time. In contrast, newer cohorts show a higher proportion of active customers, as they are still in the early stages of their lifecycle.

This distinction is important because it highlights that not all churn is negative. Some level of churn is inevitable as part of the customer lifecycle. However, the key challenge is to differentiate between natural churn and preventable churn.

By focusing on early-stage retention and improving the customer experience during the initial months, businesses can significantly reduce preventable churn. This is where the highest return on investment lies, as retaining customers early in their lifecycle has a compounding effect on their long-term value.

---

# 📈 Advanced Analytics Performed  

This project integrates multiple advanced analytical techniques to provide a comprehensive view of customer behavior. Cohort analysis is used to track customer groups over time, while lifetime value calculations quantify the total contribution of each customer.

Percentile-based segmentation ensures that customer classification is statistically meaningful, and churn analysis provides insight into retention challenges. By combining these techniques, the project moves beyond descriptive analysis and delivers actionable insights that can directly impact business strategy.

---

# 🧩 Key Learnings

This project highlights the importance of using SQL as a tool for analytical thinking rather than just data retrieval. It demonstrates how complex business questions can be broken down into structured queries and how different analytical techniques can be combined to generate meaningful insights.

Additionally, it reinforces the importance of focusing on customer behavior and long-term value, rather than relying solely on aggregate metrics like total revenue.

# 📌 Conclusion

This analysis reveals that revenue is highly concentrated among a small group of high-value customers, while a significant portion of the customer base contributes relatively little. At the same time, a large percentage of customers churn after their initial interaction, indicating a gap in retention strategy.

The findings emphasize that sustainable business growth depends not only on acquiring new customers but also on retaining and nurturing existing ones. By focusing on customer segmentation, improving early-stage engagement, and implementing targeted retention strategies, businesses can significantly enhance both revenue and customer lifetime value.
