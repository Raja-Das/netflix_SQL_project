CREATE TABLE netflix
(
show_id	 VARCHAR(6),
types  VARCHAR(10),
title  VARCHAR(150),
director  VARCHAR(208),
casts	VARCHAR(1000),
country  VARCHAR(150),	
date_added	VARCHAR(50),
release_year	INT,
rating	VARCHAR(10),
duration	VARCHAR(15),
listed_in	VARCHAR(100),
description  VARCHAR(250)
);


-- query to display the entire table
SELECT * FROM netflix;


SELECT 
   COUNT(*) AS total_content
FROM netflix;


SELECT 
   DISTINCT types
FROM netflix;


-- (1) COUNT number of MOVIES & TV SHOWS-----------------------------------------------------------------------------

SELECT types, COUNT(*) AS Total_Contents
FROM netflix 
GROUP BY types

-- (2) Most common Rating for MOVIES and TV SHOWS------------------------------------------------------------------------

SELECT 
types,
rating
FROM
(
SELECT 
types, 
rating, 
COUNT(*),
RANK() OVER(PARTITION BY types ORDER BY COUNT(*) DESC) AS ranking
FROM netflix
GROUP BY 1,2  -- 1->types , 2->rating
) AS table1

WHERE ranking=1;



-- (3) List all movies released in a specific year (eg. 2020)------------------------------------------------------------
SELECT title, release_year
FROM netflix
WHERE types = 'Movie' AND release_year=2020;


-- (4) Find the top 5 countries with the MOST CONTENT on Netflix----------------------------------------------------------

-- but one problem is here..... in some types of shows, multiple countries are there for one single show... so I have to seperate them by inserting them in an ARRAY( by "STRING_TO_ARRAY(col_name, delimeter)" fn). 
-- For seperation, I will use "UNNEST(array)" fn, which will insert each value of array in a seperate row

SELECT 
UNNEST(STRING_TO_ARRAY(country, ',')) AS new_country_list
FROM netflix;

--final code
SELECT UNNEST(STRING_TO_ARRAY(country, ',')) AS new_country_list, COUNT(*) 
FROM netflix
GROUP BY 1               -- 1 indicating 'new_country_list'
ORDER BY COUNT(*) DESC
LIMIT 5;                 --TO limit continuous rows from the top





-- (5) Identify the LONGEST Movie----------------------------------------------------------------------------------------

SELECT title, duration
FROM netflix
WHERE types='Movie' AND duration=(SELECT MAX(duration) FROM netflix);




-- (6) Find the content added in the LAST 5 YEARS----------------------------------------------------------------------------------------

-- here one problem is in 'date_added' col, date is given in text format...I need to convert it into actual date format so that DB can understand,
-- I will be using "TO_DATE(col, 'format of written date')" fn for this..

SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years'



-- (7) Find all the movies/TV shows by DIRECTOR 'Spike Lee'----------------------------------------------------------------

SELECT title, director
FROM netflix
WHERE director = 'Spike Lee';

--but if a single show is having multiple diretors, then how to get them??
--final code
SELECT title, director
FROM netflix
WHERE director LIKE '%Spike Lee%';




-- (8) List all TV Shows with more than 5 seasons-------------------------------------------------------------------------------

-- the main problem is, here duration is given in mix of no(eg. 2) & text(eg. Seasons), but need to extract the no. from the entire text
-- I will be using "SPLIT_PART()" fn  which gives the no. in text format, not numeric format
-- SPLT_PART(col_name, 'delimeter', before the delimeter how many no of arg we want to take)

SELECT title, 
SPLIT_PART(duration, ' ', 1)::numeric 
FROM netflix
WHERE types = 'TV Show' AND SPLIT_PART(duration, ' ', 1)::numeric > 5 




-- (9) Count the no. of content items in each genre------------------------------------------------------------------

SELECT  UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre, COUNT(*) AS total_content
FROM netflix
GROUP BY genre




--(10) First determine AVG no of contents/year relesed by INDIA on netflix for each year, 
 -- then RETURN...Top 5 year with highest AVG Content release.------------------------------------------------------------------


SELECT 
-- TO_DATE(date_added, 'Month DD, YYYY') AS date
EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year_extracted_from_date, 
COUNT(*) AS no_Of_Content,
ROUND(
(COUNT(*)::numeric/(SELECT COUNT(*) FROM netflix WHERE country='India')::numeric *100), 2) AS avg_content_per_year ---ROUND(decimal_value, how much decimal places you want to show) fn
FROM netflix
WHERE country='India'
GROUP BY year_extracted_from_date
ORDER BY avg_content_per_year DESC
LIMIT 5



--(11) List All the movies that are documentaries---------------------------------------------------------------------

SELECT title, listed_in
FROM netflix
WHERE  listed_in ILIKE '%Documentaries%' AND types='Movie'   -- ILIKE doesnt bother about Caps or Small letter


-- (12) Find all the content without a director------------------------------------------------------------------------

SELECT *
FROM netflix
WHERE director IS NULL	


-- (13) Find in how many movies 'Salman Khan' appears in the last 10 years------------------------------------------------

SELECT COUNT(*) AS count_of_shows
FROM netflix
WHERE casts ILIKE '%Salman Khan%'
AND 
release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10


-- (14) Find the top 10 actors who have appeared in the highest no. of movies produced in India---------------------------------------
SELECT 
UNNEST(STRING_TO_ARRAY(casts, ',')) AS actors, COUNT(*) AS total_Movies
FROM netflix
WHERE types='Movie' AND country ILIKE '%India%'
GROUP BY actors
ORDER BY total_Movies DESC
LIMIT 10


-- (15) Categorize the content based on the presense of the keywords 'kill' and 'violence' in the description field. 
--      Label content containing these keywords as'Bad_Content' and all other content as 'Good_Content'.
--      Count how many items fall into each category.
WITH new_table AS
(
SELECT 
   *,
   CASE
     WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' 
     THEN 'Bad_Content'
     ELSE 'Good_Content'
   END AS category_Of_Content
FROM netflix
)
SELECT
   category_Of_Content,
   COUNT(*) AS total_content
FROM new_table
GROUP BY category_Of_Content
ORDER BY total_content DESC