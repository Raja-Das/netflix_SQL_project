# Netflix Movies and TV Shows Data Analysis using SQL
![Netflix Logo](https://github.com/Raja-Das/netflix_SQL_project/blob/main/netflix%20logo.jpg)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objective
+ Analyze the distribution of content types (movies vs TV shows).
+ Identify the most common ratings for movies and TV shows.
+ List and analyze content based on release years, countries, and durations.
+ Explore and categorize content based on specific criteria and keywords.

## Dataset
The data for this project is sourced from the Kaggle dataset:
+ [Movies & TV Shows Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema
```sql
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
```

## Display Entire Table
```sql
-- query to display the entire table
SELECT * FROM netflix;
```

### Business Problems and Solutions
## 1. Count the Number of Movies vs TV Shows
```sql
SELECT types, COUNT(*) AS Total_Contents
FROM netflix 
GROUP BY types
```
**Objective:** Determine the distribution of content types on Netflix.

## 2. Find the Most Common Rating for Movies and TV Shows
```sql
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
```
**Objective:** Identify the most frequently occurring rating for each type of content.

## 3. List All Movies Released in a Specific Year (e.g., 2020)
```sql
SELECT title, release_year
FROM netflix
WHERE types = 'Movie' AND release_year=2020;
```
**Objective:** Retrieve all movies released in a specific year.

## 4. Find the Top 5 Countries with the Most Content on Netflix
```sql
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

```
**Objective:** Identify the top 5 countries with the highest number of content items.

## 5. Identify the Longest Movie
```sql
SELECT title, duration
FROM netflix
WHERE types='Movie' AND duration=(SELECT MAX(duration) FROM netflix);

```
**Objective:** Find the movie with the longest duration.

## 6. Find Content Added in the Last 5 Years
```sql
-- here one problem is in 'date_added' col, date is given in text format...I need to convert it into actual date format so that DB can understand,
-- I will be using "TO_DATE(col, 'format of written date')" fn for this..

SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years'

```
**Objective:** Retrieve content added to Netflix in the last 5 years.

## 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'
```sql
SELECT title, director
FROM netflix
WHERE director = 'Spike Lee';

--but if a single show is having multiple diretors, then how to get them??
--final code
SELECT title, director
FROM netflix
WHERE director LIKE '%Spike Lee%';

```
**Objective:** List all content directed by 'Rajiv Chilaka'.

## 8. List All TV Shows with More Than 5 Seasons
```sql
-- the main problem is, here duration is given in mix of no(eg. 2) & text(eg. Seasons), but need to extract the no. from the entire text
-- I will be using "SPLIT_PART()" fn  which gives the no. in text format, not numeric format
-- SPLT_PART(col_name, 'delimeter', before the delimeter how many no of arg we want to take)

SELECT title, 
SPLIT_PART(duration, ' ', 1)::numeric 
FROM netflix
WHERE types = 'TV Show' AND SPLIT_PART(duration, ' ', 1)::numeric > 5 

```
**Objective:** Identify TV shows with more than 5 seasons.

## 9. Count the Number of Content Items in Each Genre
```sql
SELECT  UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre, COUNT(*) AS total_content
FROM netflix
GROUP BY genre
```
**Objective:** Count the number of content items in each genre.

## 10. First determine AVG no of contents/year relesed by INDIA on netflix for each year, then RETURN...Top 5 year with highest AVG Content release.
```sql
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

```
**Objective:** Calculate and rank years by the average number of content releases by India.

## 11. List All Movies that are Documentaries
```sql
SELECT title, listed_in
FROM netflix
WHERE  listed_in ILIKE '%Documentaries%' AND types='Movie'   -- ILIKE doesnt bother about Caps or Small letter

```
**Objective:** Retrieve all movies classified as documentaries.

## 12. Find All Content Without a Director
```sql
SELECT *
FROM netflix
WHERE director IS NULL	
```
**Objective:** List content that does not have a director.

## 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years
```sql
SELECT * 
SELECT COUNT(*) AS count_of_shows
FROM netflix
WHERE casts ILIKE '%Salman Khan%'
AND 
release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10

```
**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

## 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
```sql
SELECT 
UNNEST(STRING_TO_ARRAY(casts, ',')) AS actors, COUNT(*) AS total_Movies
FROM netflix
WHERE types='Movie' AND country ILIKE '%India%'
GROUP BY actors
ORDER BY total_Movies DESC
LIMIT 10
```
**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

## 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
```sql
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
```
