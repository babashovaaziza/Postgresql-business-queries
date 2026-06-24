/*The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season 
 * in stores. Show all animation movies released during this period with rate more than 1, sorted alphabetically*/


/* With join */
SELECT f.film_id ,f.title, f.release_year ,f.rental_rate, c."name" 
FROM public.film f
INNER JOIN  public.film_category f_c ON f_c.film_id =f.film_id 
INNER JOIN  public.category c ON c.category_id=f_c.category_id  
WHERE LOWER(c.name) = 'animation'
AND f.rental_rate >1
AND f.release_year BETWEEN 2017 AND 2019
ORDER BY f.title;

/* With CTE */
WITH animation_films AS (
   SELECT f.film_id ,f.title, f.release_year ,f.rental_rate, c."name"
   FROM public.film f
   INNER JOIN  public.film_category f_c ON f_c.film_id =f.film_id 
   INNER JOIN  public.category c ON c.category_id=f_c.category_id
   WHERE LOWER(c.name) = 'animation'
)

SELECT a_f.film_id ,a_f.title, a_f.release_year ,a_f.rental_rate, a_f."name" 
FROM animation_films a_f
WHERE a_f.rental_rate >1
AND a_f.release_year BETWEEN 2017 AND 2019
ORDER BY a_f.title;

/* With subquery */
SELECT f.film_id ,f.title, f.release_year ,f.rental_rate
FROM public.film f
WHERE f.rental_rate > 1
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.film_id IN (
        SELECT fc.film_id
        FROM public.film_category fc
        WHERE fc.category_id = (
            SELECT c.category_id
            FROM public.category c
            WHERE LOWER(c.name) = 'animation'
        )
  )

ORDER BY f.title;

/* I prefer choose join solition.Because of logic is not so complicated as subquery and common table expression.*/
/*************************************************************************************************************/


/*The finance department requires a report on store performance to assess profitability and plan resource allocation for stores 
 * after March 2017. Calculate the revenue earned by each rental store after March 2017 (since April) (include columns: address and 
 * address2 – as one column, revenue) */

/* join solution */
SELECT store.address_id, CONCAT(a.address, ', ', COALESCE(a.address2,'')) AS location, SUM(pay.amount) AS Revenue
FROM public.store
INNER JOIN public.staff 
ON staff.store_id = store.store_id 
LEFT JOIN public.payment pay 
ON pay.staff_id = staff.staff_id
INNER JOIN public.address a 
ON store.address_id = a.address_id 
WHERE pay.payment_date >= '2017-04-01'
GROUP BY store.store_id, a.address , a.address2 
ORDER BY Revenue DESC;
/*subquery solution*/
SELECT s.store_id, (SELECT CONCAT(a.address, ', ', COALESCE(a.address2, ''))
                    FROM address a 
                    WHERE a.address_id=s.address_id ) AS location,
                    (SELECT COALESCE(SUM(p.amount), 0)
                     FROM public.payment p
                     RIGHT JOIN public.staff st ON p.staff_id = st.staff_id
                     WHERE st.store_id = s.store_id
                     AND p.payment_date >= '2017-04-01'
                     ) AS revenue
FROM store s
ORDER BY revenue DESC;
/* CTE solution */
WITH store_revenue AS (
      SELECT store.store_id,store.address_id,CONCAT(a.address, ', ', COALESCE(a.address2,'')) AS location,SUM(pay.amount) AS revenue
      FROM public.store
      INNER JOIN public.staff 
      ON staff.store_id = store.store_id 
      LEFT JOIN public.payment pay 
      ON pay.staff_id = staff.staff_id
      INNER JOIN public.address a 
      ON store.address_id = a.address_id 
      WHERE pay.payment_date >= '2017-04-01'
      GROUP BY store.store_id, a.address , a.address2 
)
SELECT 
    rs.store_id ,rs."location",rs.revenue 
    FROM store_revenue rs
    ORDER BY rs.revenue DESC;   
/*The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer interest in their 
 * films. Show top-5 actors by number of movies (released since 2015) they took part in (columns: first_name, last_name, 
 * number_of_movies, sorted by number_of_movies in descending order)*/

/* JOIN SOLUTION */

SELECT a.first_name ,a.last_name ,coalesce(COUNT(f.film_id ),0)   
FROM public.film f
INNER JOIN public.film_actor f_a ON f.film_id =f_a.film_id 
RIGHT JOIN public.actor a ON a.actor_id=f_a.actor_id 
WHERE f.release_year >= 2015
GROUP BY a.actor_id
ORDER BY COUNT(f.film_id ) DESC
LIMIT(5);

/*SUBQUERY SOLUTION*/
SELECT a.first_name ,a.last_name ,(SELECT COALESCE(COUNT(f.film_id ),0)
                                   FROM public.film f RIGHT JOIN public.film_actor fa ON f.film_id = fa.film_id 
                                   WHERE fa.actor_id = a.actor_id 
                                   AND f.release_year >= 2015) AS Number_of_films
FROM public.actor a
GROUP BY a.actor_id
ORDER by Number_of_films DESC
LIMIT(5);
/* solution with CTE */
WITH film_and_actors_after_2015 AS (
SELECT a.first_name AS afn ,a.last_name AS aln, COALESCE(COUNT(f.film_id ),0) AS number_of_films
FROM public.film f
INNER JOIN public.film_actor f_a ON f.film_id =f_a.film_id 
RIGHT JOIN public.actor a ON a.actor_id=f_a.actor_id 
WHERE f.release_year >= 2015
GROUP BY a.actor_id
)
SELECT cte.afn ,cte.aln ,cte.number_of_films 
FROM film_and_actors_after_2015 AS cte
ORDER BY cte.number_of_films DESC
LIMIT(5)



/*The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific marketing 
 * strategies. Show number of Drama, Travel, Documentary per year (include columns: release_year, number_of_drama_movies, 
 * number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is 
 * encouraged)*/

/* with join solution */
SELECT f.release_year,
COUNT(*) FILTER (WHERE LOWER(c.name) = 'drama') AS number_of_drama_movies,
COUNT(*) FILTER (WHERE LOWER(c.name) = 'travel') AS number_of_travel_movies,
COUNT(*) FILTER (WHERE LOWER(c.name) = 'documentary') AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category f_c ON f.film_id =f_c.film_id 
RIGHT JOIN public.category c ON c.category_id =f_c.category_id
GROUP BY f.release_year 
ORDER BY f.release_year DESC;

/*with subquery solution*/

SELECT f.release_year,
        (SELECT count(*)
        FROM public.film f1
        INNER JOIN public.film_category f_c ON f1.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'drama' 
        AND f1.release_year = f.release_year) AS number_of_drama_movies,
        (SELECT count(*)
        FROM public.film f1
        INNER JOIN public.film_category f_c ON f1.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'travel' 
        AND f1.release_year = f.release_year) AS number_of_travel_movies,
        (SELECT count(*)
        FROM public.film f1
        INNER JOIN public.film_category f_c ON f1.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'documentary' 
        AND f1.release_year = f.release_year) AS number_of_documentary_movies
FROM public.film f
GROUP BY f.release_year
ORDER BY f.release_year DESC

/* with CTE solution */

WITH drama_movies AS(
 SELECT f.release_year AS ry, COUNT(*) AS number_of_drama_movies
        FROM public.film f
        INNER JOIN public.film_category f_c ON f.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'drama' 
        GROUP BY f.release_year 
),
travel_movies AS(
 SELECT f.release_year AS ry, COUNT(*) AS number_of_travel_movies
        FROM public.film f
        INNER JOIN public.film_category f_c ON f.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'travel' 
        GROUP BY f.release_year 
),
documentary_movies AS(
 SELECT f.release_year AS ry, count(*) AS number_of_documentary_movies
        FROM public.film f
        INNER JOIN public.film_category f_c ON f.film_id =f_c.film_id 
        RIGHT JOIN public.category c ON c.category_id =f_c.category_id
        WHERE LOWER(c.name) = 'documentary' 
        GROUP BY f.release_year 
)
SELECT f.release_year,
        COALESCE((SELECT dm.number_of_drama_movies  
        FROM drama_movies dm
        WHERE dm.ry = f.release_year ),0) AS Number_of_drama_movies,
        COALESCE((SELECT tm.number_of_travel_movies  
        FROM travel_movies tm
        WHERE tm.ry = f.release_year ),0) AS Number_of_travel_movies,
        COALESCE((SELECT ddm.number_of_documentary_movies  
        FROM documentary_movies ddm
        WHERE ddm.ry = f.release_year ),0) AS Number_of_documentary_movies       
FROM film f
GROUP BY f.release_year 
ORDER BY f.release_year DESC;




/*The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores 
 revenue. Show which three employees generated the most revenue in 2017? */
/*solution with join*/
SELECT s.first_name _name , s.last_name, sum(pay.amount ), s.store_id 
FROM public.staff s 
LEFT JOIN public.payment pay ON s.staff_id = pay.staff_id 
WHERE pay.payment_date >= '2017-01-01'
  AND pay.payment_date <  '2018-01-01'
GROUP BY s.staff_id 
ORDER BY SUM(pay.amount ) desc
LIMIT(3);
/*solution with subquery*/
SELECT s.first_name _name , s.last_name, (select sum(p.amount) 
                                          from public.payment p 
                                          where p.staff_id = s.staff_id 
                                          and (p.payment_date >= '2017-01-01'
                                          AND p.payment_date <  '2018-01-01') ) as staff_revenue ,s.store_id 
FROM public.staff s 
GROUP BY s.staff_id 
ORDER BY staff_revenue desc
LIMIT(3);
/*solution with CTE*/

with Common_table_expression as (
     SELECT s.first_name AS sfn, s.last_name as sln, sum(pay.amount ) as strev, s.store_id as stid
     FROM public.staff s 
     LEFT JOIN public.payment pay ON s.staff_id = pay.staff_id 
     WHERE pay.payment_date >= '2017-01-01'
     AND pay.payment_date <  '2018-01-01'
GROUP BY s.staff_id 
)
select cte.sfn, cte.sln,cte.strev,cte.stid 
from Common_table_expression cte
ORDER BY cte.strev desc
LIMIT(3);


/*The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts. 
 * Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?
 *  To determine expected age please use*/

/*solution with join*/
SELECT f.title, count(r.rental_id),
    CASE f.rating
        WHEN 'G' THEN '0-6'
        WHEN 'PG' THEN '7-12'
        WHEN 'PG-13' THEN '13-16'
        WHEN 'R' THEN '17-20'
        WHEN 'NC-17' THEN '21+'
        ELSE 'Unknown'
    END AS expected_age 
FROM public.film f
LEFT JOIN public.inventory i ON f.film_id = i.film_id 
LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id 
GROUP BY f.film_id
ORDER BY count(r.rental_id) DESC
LIMIT(5);

/*solution with subquery*/
SELECT 
    f.title,
    COALESCE((
        SELECT COUNT(r.rental_id)
        FROM public.inventory i
        LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
        WHERE i.film_id = f.film_id
    ), 0) AS number_of_rentals,
    CASE f.rating
        WHEN 'G'       THEN '0-6'
        WHEN 'PG'      THEN '7-12'
        WHEN 'PG-13'   THEN '13-16'
        WHEN 'R'       THEN '17-20'
        WHEN 'NC-17'   THEN '21+'
        ELSE 'Unknown'
    END AS expected_age
FROM public.film f
ORDER BY number_of_rentals DESC
LIMIT (5);

/*Solution with CTE*/
with common_table_expression as (
  SELECT f.title as ft, count(r.rental_id) as renc,
    CASE f.rating
        WHEN 'G' THEN '0-6'
        WHEN 'PG' THEN '7-12'
        WHEN 'PG-13' THEN '13-16'
        WHEN 'R' THEN '17-20'
        WHEN 'NC-17' THEN '21+'
        ELSE 'Unknown'
    END AS expected_age 
FROM public.film f
LEFT JOIN public.inventory i ON f.film_id = i.film_id 
LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id 
GROUP BY f.film_id
  
)
select cte.ft ,cte.renc ,cte.expected_age 
from common_table_expression cte
ORDER BY cte.renc DESC
LIMIT (5);

/*According to the result audiences PG (Parental Guidance): Suitable for children, but parental guidance is advised. The primary audience is around 8–12 years old.
PG-13 (Parents Strongly Cautioned): Teens aged 13–16 are the main audience; some content may not be appropriate for younger children without parental supervision.
NC-17 (Adults Only): Intended for adults; viewers under 17 are not allowed.*/





/*The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted
 *  promotional campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable
 *  film stars
The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
V1: gap between the latest release_year and current year per each actor;
V2: gaps between sequential films per each actor;
 */

/* V1 solution with join */

SELECT a.first_name, a.last_name  ,(EXTRACT(YEAR FROM CURRENT_DATE)-max(f.release_year)) AS gap 
FROM public.film f
INNER JOIN public.film_actor f_a ON f.film_id = f_a.film_id 
INNER JOIN public.actor a ON a.actor_id = f_a.actor_id 
GROUP BY a.actor_id
ORDER BY (EXTRACT(YEAR FROM CURRENT_DATE)-max(f.release_year)) DESC;

/*V1 Soluton with subquery*/
SELECT a.first_name, a.last_name, (select EXTRACT(YEAR FROM CURRENT_DATE)-max(f.release_year)  
                                   from film_actor fa inner join film f on fa.film_id = f.film_id 
                                   where fa.actor_id = a.actor_id) as gap
from public.actor a
GROUP BY a.actor_id
ORDER BY  gap DESC;

/*V1 Soluton with CTE*/
with common_table_expression as (
    SELECT a.first_name as afn, a.last_name as aln ,(EXTRACT(YEAR FROM CURRENT_DATE)-max(f.release_year)) AS gap 
    FROM public.film f
    INNER JOIN public.film_actor f_a ON f.film_id = f_a.film_id 
    INNER JOIN public.actor a ON a.actor_id = f_a.actor_id 
    GROUP BY a.actor_id
)
select cte.afn,cte.aln,cte.gap 
from common_table_expression as cte
ORDER BY  gap DESC;

/* V solution with CTE,Subquery,join combined*/

WITH actor_unique_years AS (
    -- Har bir aktyorning chiqqan yillarini unique qilib olamiz
    SELECT 
        a.actor_id as aid,
        a.first_name firstn,
        a.last_name as lastn,
        f.release_year as ry
    FROM public.actor a
    JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    JOIN public.film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name, f.release_year
    order by a.actor_id
),
actor_year_gaps as (
                  select aid,firstn,lastn, ry,(select min(ry-f.release_year)
                                             FROM public.film f
                                             JOIN public.film_actor f_a ON f.film_id = f_a.film_id 
                                             JOIN public.actor a ON a.actor_id = f_a.actor_id 
                                             where f_a.actor_id = aid and ry-f.release_year > 0                  
                                                                                                ) as gaps
from actor_unique_years auy)

select ayg.aid,ayg.firstn,ayg.lastn,max(ayg.gaps) as Maximum_Gaps
from actor_year_gaps ayg
group by ayg.aid,ayg.firstn,ayg.lastn 
order by max(ayg.gaps) DESC





















 



