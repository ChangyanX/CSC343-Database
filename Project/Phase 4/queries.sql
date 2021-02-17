
-- Four investigative questions we plan to answer using this datas  

-- 1. What is the busiest time of the year for airbnbs in seattle and how much does price change  
-- (i.e. the average price for apartments among off seasons and peak tourist seasons?)  
DROP VIEW IF EXISTS occupiedListing CASCADE;
DROP VIEW IF EXISTS allListing CASCADE;

create view occupiedListing as
select extract(month from L_date) as month, count(*) as booked_count, avg(daily_price::money::numeric) as avgPrice
from listingBooking
where available = 't'
group by extract(month from L_date);

create view allListing as
select extract(month from L_date) as month, count(*) as all_count
from listingBooking
group by month;


select o.month, o.booked_count/a.all_count::float as occupancy_rate, o.avgprice
from occupiedListing o join allListing a using (month);

-- 2. Who are the top rating (i.e hosts who has ever got a highest rating) superhosts (i.e. hosts who have a superhost badge) for each neighbourhood in Seattle?

DROP VIEW IF EXISTS a CASCADE;
DROP VIEW IF EXISTS highest_rating_perNH CASCADE; 


-- find all superhosts for each neighbourhood
CREATE VIEW a AS 
SELECT l.host_id, host_name, listing_id, neighbourhood, review_scores_rating
FROM HostInfo h 
JOIN ListingInfo l USING (host_id)
JOIN NeighborhoodInfo n USING (listing_id)
JOIN Score s USING (listing_id)
WHERE host_is_superhost=true
ORDER BY neighbourhood, l.host_id;


-- find the highest rating for each neighbourhood
CREATE VIEW highest_rating_perNH AS 
SELECT DISTINCT neighbourhood, max(review_scores_rating) AS max_rating
FROM a
GROUP BY neighbourhood
ORDER BY neighbourhood;



SELECT DISTINCT neighbourhood, host_id, host_name
FROM a 
JOIN highest_rating_perNH h USING (neighbourhood)
WHERE a.neighbourhood=h.neighbourhood
AND a.review_scores_rating=h.max_rating
ORDER BY neighbourhood;




-- 3. How are the mainstream property types and non-mainstream property types associated with the listing's score? 
--We define the "mainstream property type" to be the property type that takes up at least 2% of all property types of the listings in Seattle. 
-- for the first table: report the average score, highest score, lowest score for each property type which is one of the main-stream property types. And rank the results in descending order by the average score.
-- the second table is for non-main-stream property types. 

CREATE TABLE PropertyType_to_Scores_principle(
	property_Type varchar(10000),
	avgscore float, 
	highest_score float, 
	lowest_score float
);

CREATE TABLE PropertyType_to_Scores_select(
	property_Type varchar(10000),
	avgscore float, 
	highest_score float, 
	lowest_score float
);


-- find the target property types

CREATE VIEW all_property_types AS
SELECT DISTINCT property_Type,  
COUNT(*) AS num_listings, 
(SELECT COUNT(*) FROM ListingInfo) AS tot_num_listings,
CASE
	WHEN COUNT(*)::float / (SELECT COUNT(*) FROM ListingInfo) >= 0.02 THEN TRUE
	ELSE FALSE
END AS is_main_stream,
COUNT(*)::float / (SELECT COUNT(*) FROM ListingInfo) AS property_percentage
FROM ListingInfo
GROUP BY property_Type
ORDER BY property_Type;


CREATE VIEW target_property_types_principle AS
SELECT property_Type, is_main_stream, property_percentage
FROM all_property_types
WHERE is_main_stream=true
ORDER BY property_Type;


CREATE VIEW target_property_types_select AS
SELECT property_Type, is_main_stream, property_percentage
FROM all_property_types
WHERE is_main_stream=false
ORDER BY property_Type;


-- find scores corresponding to each property type for all property types

CREATE VIEW all_property_Type_scores AS
SELECT DISTINCT property_Type,
SUM(review_scores_rating)::float / COUNT(*)::float AS avgscore,
MAX(review_scores_rating) AS highest_score,
MIN(review_scores_rating) AS lowest_score
FROM Score s
JOIN ListingInfo ls USING (listing_id)
GROUP BY property_Type
ORDER BY avgscore DESC;



-- Obtain the result and insert into the table

INSERT INTO PropertyType_to_Scores_principle
SELECT property_Type, avgscore, highest_score, lowest_score
FROM all_property_Type_scores 
RIGHT JOIN target_property_types_principle USING (property_Type)
ORDER BY avgscore DESC;


INSERT INTO PropertyType_to_Scores_select
SELECT property_Type, avgscore, highest_score, lowest_score
FROM all_property_Type_scores 
RIGHT JOIN target_property_types_select USING (property_Type)
ORDER BY avgscore DESC;

select * from PropertyType_to_Scores_principle;
select * from PropertyType_to_Scores_select;
