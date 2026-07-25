--Creating movie dimension table
CREATE TABLE movie_dim (
movie_id varchar(50) PRIMARY KEY,
title TEXT,
release_year int,
rank int
);

--Inserting values into movie_dim table from movies table
INSERT INTO movie_dim (
movie_id, 
title, 
release_year, 
rank
)
SELECT id, title, release_year, rank
FROM movies;

--Checking if the values are inserted correctly
SELECT *
FROM movie_dim;

--Creating directors' dimension table
CREATE TABLE director_dim (
director_id SERIAL PRIMARY KEY,
movie_id varchar(50) REFERENCES movie_dim(movie_id),
director_name TEXT
);

--Inserting values into director_dim table from movies table
INSERT INTO director_dim (
movie_id, 
director_name
)
SELECT id, director
FROM movies;

--Creating writers' dimention table
CREATE TABLE writer_dim (
writer_id SERIAL PRIMARY KEY,
movie_id varchar(50) REFERENCES movie_dim(movie_id),
writer_name TEXT
);

--Inserting values into writer_dim table from movies table
INSERT INTO writer_dim (
movie_id,
writer_name
)
SELECT id, writer 
FROM movies;

--Creating genre dimension table
CREATE TABLE genre_dim (
genre_id SERIAL PRIMARY KEY,
movie_id varchar(50) REFERENCES movie_dim(movie_id),
genre_name TEXT
);

--Inserting values into genre_dim table from movies table
INSERT INTO genre_dim (
movie_id,
genre_name
)
SELECT id, genre
FROM movies;

--Creating movie facts table
CREATE TABLE movie_fact (
movie_id varchar(50) PRIMARY KEY,
avg_rating NUMERIC,
num_votes int,
runtime int
);

--Inserting values into movie_fact table
INSERT INTO movie_fact (
movie_id,
avg_rating,
num_votes,
runtime
)
SELECT id, avg_rating, num_votes, runtime
FROM movies;

--In this step I examined the tables to see what needs to be cleaned or fixed
SELECT * 
FROM genre_dim; --column genre contains multiple values, 1NF rule broken

--I delete wrong values from the table
TRUNCATE TABLE genre_dim;

--Inserting data again but the column genre_name now contains only one value
INSERT INTO genre_dim (
movie_id, 
genre_name)
SELECT id AS movie_id,
    TRIM(unnest(string_to_array(genre, ','))) AS genre_name
FROM movies;

--Correcting tables director_dim and writer_dim as they have the same issue
TRUNCATE TABLE director_dim;
TRUNCATE TABLE writer_dim;

--Inserting data again
INSERT INTO director_dim (
movie_id, 
director_name)
SELECT id AS movie_id,
    TRIM(unnest(string_to_array(director, ','))) AS director_name
FROM movies;

INSERT INTO writer_dim (
movie_id, 
writer_name)
SELECT id AS movie_id,
    TRIM(unnest(string_to_array(writer, ','))) AS writer_name
FROM movies;

--Creating cast table from streaming platform tables (disney, netflix, prime)
CREATE TABLE cast_dim (
actor_id SERIAL PRIMARY KEY,
movie_id varchar(50),
actor_name TEXT
);

--Inserting values into cast_dim from various other tables

INSERT INTO cast_dim (
movie_id, 
actor_name
)
SELECT
    CONCAT('disney_', show_id) AS movie_id, --to avoid duplicates from various tables
    TRIM(unnest(string_to_array("cast", ','))) AS actor_name
FROM disney;

INSERT INTO cast_dim (
movie_id, 
actor_name
)
SELECT
    CONCAT('netflix_', show_id) AS movie_id,
    TRIM(unnest(string_to_array("cast", ','))) AS actor_name
FROM netflix;

INSERT INTO cast_dim (
movie_id, 
actor_name
)
SELECT
    CONCAT('prime_', show_id) AS movie_id,
    TRIM(unnest(string_to_array("cast", ','))) AS actor_name
FROM prime;

--Dropping " min" from duration column and converting to integer
ALTER TABLE disney 
ADD COLUMN duration_min INT;

UPDATE disney
SET duration_min = NULLIF(split_part(duration, ' ', 1), '')::INT;
ALTER TABLE disney DROP COLUMN duration;

ALTER TABLE netflix 
ADD COLUMN duration_min INT;

UPDATE netflix
SET duration_min = NULLIF(split_part(duration, ' ', 1), '')::INT;
ALTER TABLE netflix DROP COLUMN duration;

ALTER TABLE prime 
ADD COLUMN duration_min INT;

UPDATE prime
SET duration_min = NULLIF(split_part(duration, ' ', 1), '')::INT;
ALTER TABLE prime DROP COLUMN duration;

--Changing date_added data type from string to DATE
ALTER TABLE disney
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, 'DD.MM.YYYY');

ALTER TABLE netflix
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, 'DD.MM.YYYY');

ALTER TABLE prime
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, 'DD.MM.YYYY');

select * from disney

ALTER TABLE disney
DROP COLUMN director,
DROP COLUMN country,
DROP COLUMN rating;

ALTER TABLE netflix
DROP COLUMN director,
DROP COLUMN country,
DROP COLUMN rating;

ALTER TABLE prime
DROP COLUMN director,
DROP COLUMN country,
DROP COLUMN rating;

select * from netflix

--Normalizing titles for accurate joining across datasets with different formatting
ALTER TABLE movie_dim ADD COLUMN title_clean TEXT;
UPDATE movie_dim SET title_clean = LOWER(TRIM(title));

ALTER TABLE disney ADD COLUMN title_clean TEXT;
UPDATE disney SET title_clean = LOWER(TRIM(title));

ALTER TABLE netflix ADD COLUMN title_clean TEXT;
UPDATE netflix SET title_clean = LOWER(TRIM(title));

ALTER TABLE prime ADD COLUMN title_clean TEXT;
UPDATE prime SET title_clean = LOWER(TRIM(title));
