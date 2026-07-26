-- 1. BASIC ANALYSIS

--Which genres are the most popular?
SELECT COUNT(movie_id) AS movie_count, genre_name
FROM genre_dim
GROUP BY genre_name
ORDER BY movie_count DESC
LIMIT 3;

--In what year was the most movies released
SELECT release_year, COUNT(movie_id) as movie_count
FROM movie_dim
GROUP BY release_year
ORDER BY movie_count DESC
LIMIT 1;

-- 2. ADVANCED ANALYSIS
--Is there a correlation between num_votes and avg_rating? Do movies with high number of votes have lower rating?
SELECT
    CASE
        WHEN num_votes < 1000 THEN '< 1,000 votes'
        WHEN num_votes < 10000 THEN '1,000 - 9,999 votes'
        WHEN num_votes < 100000 THEN '10,000 - 99,999 votes'
        ELSE '100,000+ votes'
    END AS vote_bracket,
    COUNT(*) AS movie_count,
    ROUND(AVG(avg_rating), 2) AS average_rating
FROM movie_fact
GROUP BY vote_bracket
ORDER BY MIN(num_votes); --hipotesis not supported, movies with high number of votes have higher rating

--Which genres have the highest average rating?
SELECT ROUND(AVG(movie_fact.avg_rating), 2) AS average_rating, genre_dim.genre_name
FROM movie_fact
JOIN genre_dim
	ON movie_fact.movie_id = genre_dim.movie_id
GROUP BY genre_dim.genre_name
HAVING COUNT(movie_fact.movie_id) >= 20 --excluding genres with less than 20 movies
ORDER BY average_rating DESC
LIMIT 5;



/*Are there directors who consequently (min.3 movies) have movies with a high average rating 
(above average for the whole table)? */
WITH director_stats AS (
    SELECT 
        director_dim.director_name,
        COUNT(director_dim.movie_id) AS movie_count,
        ROUND(AVG(movie_fact.avg_rating), 2) AS director_avg_rating
    FROM director_dim
    JOIN movie_fact 
        ON director_dim.movie_id = movie_fact.movie_id
    GROUP BY director_dim.director_name
    HAVING COUNT(director_dim.movie_id) >= 3
),
overall_avg AS (
    SELECT ROUND(AVG(avg_rating), 2) AS overall_avg_rating
    FROM movie_fact
)
SELECT director_name, movie_count, director_avg_rating
FROM director_stats, overall_avg
WHERE director_avg_rating > overall_avg_rating
ORDER BY director_avg_rating DESC;



--How many movies were added across the streaming platforms in each year? Is it a growing trend?
SELECT
    EXTRACT(YEAR FROM date_added) AS year_added,
	'Disney' AS platform,
    COUNT(*) AS titles_added
FROM disney
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)

UNION ALL

SELECT
    EXTRACT(YEAR FROM date_added) AS year_added,
	'Netflix' AS platform,
    COUNT(*) AS titles_added
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)

UNION ALL

SELECT
    EXTRACT(YEAR FROM date_added) AS year_added,
	'Prime' AS platform,
    COUNT(*) AS titles_added
FROM prime
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year_added, platform;

--Which streaming platform has the highest rated movies?
WITH streaming_titles AS (
    SELECT title, release_year, 'Disney' AS platform 
	FROM disney
	
    UNION ALL
    SELECT title, release_year, 'Netflix' AS platform 
	FROM netflix
	
    UNION ALL
    SELECT title, release_year, 'Prime' AS platform 
	FROM prime
)
SELECT
    s.platform,
    COUNT(DISTINCT m.movie_id) AS matched_movies,
    ROUND(AVG(f.avg_rating), 2) AS average_rating
FROM streaming_titles s
JOIN movie_dim m
    ON LOWER(TRIM(s.title)) = LOWER(TRIM(m.title))
    AND s.release_year = m.release_year
JOIN movie_fact f
    ON m.movie_id = f.movie_id
GROUP BY s.platform
ORDER BY average_rating DESC;