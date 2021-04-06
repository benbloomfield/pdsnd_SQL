/*Query 1 - Store 1 Rental Performance*/
WITH t1 AS(
           SELECT (DATE_PART('year', rental_date) || '/0' || DATE_PART('month', rental_date)) AS rent_date, rental_id, staff_id
           FROM rental
           ),

	 t2 AS(
		   SELECT t1.rent_date, st.store_id, COUNT(*) AS num_rent
		   FROM t1
		   JOIN staff s ON t1.staff_id = s.staff_id
	       JOIN store st ON s.staff_id = st.manager_staff_id
	       GROUP BY 2, 1
           )

SELECT rent_date AS "Month of Rental", num_rent AS "Number of Rentals",
	   num_rent - COALESCE(LAG(num_rent) OVER (ORDER BY rent_date), '0') AS "Change in Number of Rentals"
FROM t2
WHERE store_id = 1;

/*Query 2 - Top 10 Customers in top decile country*/

WITH t1 AS(
		   SELECT ci.country_id, NTILE(10) OVER (ORDER BY COUNT(*)) AS Decile
           FROM customer c
           JOIN address a ON c.address_id = a.address_id
           JOIN city ci ON a.city_id = ci.city_id
           GROUP BY 1
           ),

     t2 AS(
           SELECT (c.first_name || ' ' || c.last_name) AS full_name, SUM(p.amount) AS "Total Payments", t1.Decile AS "Country Decile",
    	   CASE WHEN t1.Decile = 10 THEN 'Top Decile' ELSE 'Not Top Decile' END AS country_cat
           FROM customer c
           JOIN payment p ON c.customer_id = p.customer_id
           JOIN address a ON c.address_id = a.address_id
           JOIN city ci ON a.city_id = ci.city_id
           JOIN t1 ON ci.country_id = t1.country_id
           GROUP BY 1, 3
           ORDER BY 2 DESC
           LIMIT 10
           )

SELECT country_cat AS "Country Categorisation", COUNT(*) AS "Number of Customers"
FROM t2
GROUP BY 1;

/*Query 3 - Top category by rental count in Western Europe countries*/

WITH t1 AS(
           SELECT (co.country), c.name, COUNT (*) AS num_rent
           FROM country co
           JOIN city ci ON ci.country_id = co.country_id
           JOIN address a ON a.city_id = ci.city_id
           JOIN customer cu ON cu.address_id = a.address_id
           JOIN rental r ON r.customer_id = cu.customer_id
           JOIN inventory i ON i.inventory_id = r.inventory_id
           JOIN film_category fc ON fc.film_id = i.film_id
           JOIN category c ON c.category_id = fc.category_id
           WHERE co.country IN ('France', 'Germany', 'Holy See (Vatican City State)', 'Italy', 'Liechtenstein', 'Netherlands', 'Spain', 'Switzerland', 'United Kingdom')
           GROUP BY 1, 2
		   ),

	 t2 AS(
           SELECT country, MAX(num_rent) AS max_cat
		   FROM t1
		   GROUP BY 1
		   )

SELECT t1.country AS "Country", t1.name AS "Most Popular Category", t2.max_cat AS "Number of Rentals"
FROM t1
JOIN t2 ON t1.country = t2.country AND t1.num_rent = t2.max_cat
ORDER BY 1;

/*Query 4 - Top category by sales*/

SELECT c.name AS "Category", SUM(p.amount) AS "Total Sales"
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY 1
ORDER BY 2 DESC;
