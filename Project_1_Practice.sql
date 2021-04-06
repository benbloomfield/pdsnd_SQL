/*Query to return how many times each 'family' movie is rented*/

WITH cat_filt AS(
                SELECT category_id, name
                FROM category
                WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
                ),

    the_table AS(
                SELECT f.title, c.name
                FROM cat_filt c
                JOIN film_category fc ON c.category_id = fc.category_id
                JOIN film f ON fc.film_id = f.film_id
                JOIN inventory i ON f.film_id = i.film_id
                JOIN rental r ON i.inventory_id = r.inventory_id
                )

SELECT DISTINCT(title), name, COUNT (*) OVER (PARTITION BY title ORDER BY name)
FROM the_table
ORDER BY 2;

/*Query to return rental duration of family movies by quartile*/

SELECT f.title, c.name, f.rental_duration, NTILE(4) OVER (ORDER BY f.rental_duration) AS std_q
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))

/*Query to return count of rental duration by quartile*/

WITH t1 AS(
			SELECT f.title, c.name, f.rental_duration, NTILE(4) OVER (ORDER BY f.rental_duration) AS std_q
			FROM film f
			JOIN film_category fc ON f.film_id = fc.film_id
			JOIN category c ON fc.category_id = c.category_id
			WHERE name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))

SELECT DISTINCT(name), std_q, COUNT(*) OVER (PARTITION BY std_q, name ORDER BY name)
FROM t1
ORDER BY 1, 2;

/*Query to return count of rentals per store for each month*/

WITH t1 AS(
            SELECT DATE_PART('month', rental_date) AS r_month, DATE_PART('year', rental_date) AS r_year, rental_id, staff_id
            FROM rental)

SELECT t1.r_month, t1.r_year, st.store_id, COUNT(*)
FROM t1
JOIN staff s ON t1.staff_id = s.staff_id
JOIN store st ON s.staff_id = st.manager_staff_id
GROUP BY 2, 1, 3
ORDER BY 4 DESC;

/*Query to return top 10 paying customers, payment count and amount by month in 2007*/

WITH t1 AS(
            SELECT c.customer_id, (c.first_name || ' ' || c.last_name) full_name, SUM(p.amount)
            FROM customer c
            JOIN payment p ON c.customer_id = p.customer_id
            GROUP BY 1, 2
            ORDER BY 3 DESC
            LIMIT 10
            ),

SELECT DATE_TRUNC('month', p.payment_date) p_month, t1.full_name, COUNT(*) num_pay, SUM(p.amount) sum_pay
FROM t1
JOIN payment p ON t1.customer_id = p.customer_id
WHERE DATE_PART('year', p.payment_date) = 2007
GROUP BY 1, 2
ORDER BY 2;

/*Q6*/

WITH t1 AS(
            SELECT c.customer_id, (c.first_name || ' ' || c.last_name) full_name, SUM(p.amount)
            FROM customer c
            JOIN payment p ON c.customer_id = p.customer_id
            GROUP BY 1, 2
            ORDER BY 3 DESC
            LIMIT 10
            ),

     t2 AS(
            SELECT DATE_TRUNC('month', p.payment_date) p_month, t1.full_name, COUNT(*) num_pay, SUM(p.amount) sum_pay
            FROM t1
            JOIN payment p ON t1.customer_id = p.customer_id
            WHERE DATE_PART('year', p.payment_date) = 2007
            GROUP BY 1, 2
            ORDER BY 2
            )

SELECT p_month, full_name, num_pay, sum_pay,
       sum_pay - LAG(sum_pay) OVER (ORDER BY full_name, p_month, sum_pay) AS pay_diff
FROM t2;

/*dynamic max diff, make t3 from outer query above*/

t4 AS (SELECT MAX(pay_diff) max_diff FROM t3)

SELECT full_name, pay_diff
FROM t3
GROUP BY 1, 2
HAVING pay_diff = (SELECT max_diff FROM t4)
