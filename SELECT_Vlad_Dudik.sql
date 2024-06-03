--Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?

--1 способ, 3 подзапроса, и переиспользование их друг в друге.
WITH staff_revenue AS (
	SELECT CONCAT(s.first_name, ' ', s.last_name) AS full_name,
		s.store_id,
		p.amount,
		p.payment_date
	FROM staff s
	INNER JOIN payment p ON s.staff_id = p.staff_id 
),
store_staff_revenue AS (
	SELECT 
		store_id,
		full_name,
		SUM(amount) as total_amount
	FROM staff_revenue
	WHERE EXTRACT(YEAR FROM payment_date) = 2017
	GROUP BY store_id, full_name
)
	
SELECT 
    s.store_id,
    s.full_name,
    s.total_amount
FROM 
    store_staff_revenue s
WHERE 
    s.total_amount = (
        SELECT MAX(total_amount) 
        FROM store_staff_revenue r
        WHERE r.store_id = s.store_id
    )
ORDER BY s.store_id, s.full_name

-- 2 способ, 2 подзапроса и их джоин
WITH staff_revenue AS (
    SELECT CONCAT(s.first_name, ' ', s.last_name) AS full_name,
           s.store_id,
           SUM(p.amount) AS total
    FROM staff s
    INNER JOIN payment p ON s.staff_id = p.staff_id 
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
	GROUP BY store_id, full_name
),
max_revenue_per_store AS (
    SELECT store_id, MAX(total) AS max_revenue
    FROM staff_revenue
    GROUP BY store_id
)
SELECT sr.store_id, 
       sr.full_name, 
       sr.total
FROM staff_revenue sr
INNER JOIN max_revenue_per_store mr
    ON sr.store_id = mr.store_id
    AND sr.total = mr.max_revenue
ORDER BY sr.store_id, sr.full_name


--Which five movies were rented more than the others, and what is the expected age of the audience for these movies?
--1 способ, использование 3 джоинов
SELECT 
	f.title,
	f.rating,
	COUNT(r.rental_id) as rent_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY f.title, f.rating
ORDER BY rent_count DESC
LIMIT 5

--2 способ, подзапрос, результат отличается так как несколько фильмов были взяты в прокат 64 раза
SELECT title, rating
FROM film f
WHERE film_id IN (
	SELECT 
	film_id
	FROM rental r
	JOIN inventory i ON i.inventory_id = r.inventory_id
	GROUP BY film_id
	ORDER BY COUNT(r.rental_id) DESC
	LIMIT 5)


--Which actors/actresses didn't act for a longer period of time than the others?
--1 способ, сколько актеры вообще не снимались относительной текущей даты
SELECT DISTINCT
	CONCAT(a.first_name, ' ', a.last_name) AS full_name,
	current_date,
	MAX(f.release_year) as last_release,
	EXTRACT(YEAR FROM current_date) - MAX(f.release_year) AS years_didnt_act
FROM actor a
JOIN film_actor fa ON fa.actor_id = a.actor_id
JOIN film f ON f.film_id = fa.film_id
GROUP BY full_name
ORDER BY years_didnt_act DESC

--2 способ, 
WITH actors_films AS (
SELECT 
	a.actor_id,
	CONCAT(a.first_name, ' ', a.last_name) AS full_name,
	f.release_year,
	ROW_NUMBER() OVER(PARTITION BY a.actor_id ORDER BY f.release_year) AS film_order
	FROM actor a
	JOIN film_actor fa ON fa.actor_id = a.actor_id
	JOIN film f ON fa.film_id = f.film_id
),
film_diff AS (
	SELECT 
	af1.actor_id,
	af1.full_name,
	af1.release_year AS current_act_year,
	af2.release_year AS previous_act_year,
	af1.release_year - af2.release_year AS years_between_films
	FROM actors_films af1
	JOIN actors_films af2 ON af1.actor_id = af2.actor_id AND af1.film_order = af2.film_order + 1
)
SELECT
	actor_id,
	full_name,
	current_act_year,
	previous_act_year,
	years_between_films
FROM film_diff 
WHERE years_between_films > 0
ORDER BY years_between_films DESC


	

