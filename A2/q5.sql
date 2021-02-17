-- Lure Them Back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20),
    email TEXT NOT NULL,
    usage INT,
    decline INT,
    missed INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:


-- PART I:
-- Find patrons who were 
    -- active in every month of 2018, 
    -- active in at least five months of 2019, 
    -- had at least one month in 2019 when they were not active, 
    -- and have checked out nothing in 2020. 

-- active in every month of 2018
CREATE VIEW PatronActiveAllMonths2018 AS
SELECT patron
FROM Checkout
WHERE EXTRACT(year FROM checkout_time)=2018
GROUP BY patron
HAVING COUNT(DISTINCT EXTRACT(month FROM checkout_time))>=12
ORDER BY patron;

-- active in at least five months of 2019
CREATE VIEW PatronActiveAtLeast5Month2019 AS
SELECT patron
FROM Checkout
WHERE EXTRACT(year FROM checkout_time)=2019
GROUP BY patron
HAVING COUNT(DISTINCT EXTRACT(month FROM checkout_time))>=5
ORDER BY patron;

-- had at least one month in 2019 when they were not active (= all patron - patron active all-year-around in 2019)
CREATE VIEW allPatron AS
SELECT card_number AS patron
FROM Patron
ORDER BY patron;

CREATE VIEW PatronActiveAllMonth2019 AS
SELECT patron
FROM Checkout
WHERE EXTRACT(year FROM checkout_time)=2019
GROUP BY patron
HAVING COUNT(DISTINCT EXTRACT(month FROM checkout_time))=12
ORDER BY patron;

CREATE VIEW PatronInactiveAtLeast1Month2019 AS
(SELECT patron FROM allPatron) EXCEPT (SELECT patron FROM PatronActiveAllMonth2019);

-- have checked out nothing in 2020 (= all patron - patron ever checked out in 2020)
CREATE VIEW PatronCheckedoutNothing2020 AS
(SELECT patron FROM allPatron) EXCEPT (
SELECT DISTINCT patron
FROM Checkout
WHERE EXTRACT(year FROM checkout_time)=2020
GROUP BY patron
ORDER BY patron);

-- Find all patron satisfies the above-four criteria
CREATE VIEW TargetPatrons AS
(SELECT patron FROM PatronActiveAllMonths2018) 
                              INTERSECT (SELECT patron FROM PatronActiveAtLeast5Month2019) 
                              INTERSECT (SELECT patron FROM PatronInactiveAtLeast1Month2019) 
                              INTERSECT (SELECT patron FROM PatronCheckedoutNothing2020);

-- PART II:
-- email 
CREATE VIEW Email AS
SELECT DISTINCT tp.patron AS patron, 
CASE 
	WHEN p.email IS NULL THEN 'none'
	ELSE p.email
END AS email
FROM Patron p RIGHT JOIN TargetPatrons tp ON p.card_number=tp.patron
ORDER BY tp.patron;
                              
-- usage
                              
CREATE VIEW Usage AS
SELECT DISTINCT tp.patron AS patron, COUNT(DISTINCT holding) AS usage
FROM Checkout c RIGHT JOIN TargetPatrons tp ON c.patron=tp.patron
GROUP BY tp.patron
ORDER BY tp.patron;                  
                              
-- decline

CREATE VIEW Patron2018checkouts AS
SELECT DISTINCT tp.patron AS patron, COUNT(*) AS num_checkout_2018
FROM Checkout c RIGHT JOIN TargetPatrons tp ON c.patron=tp.patron
WHERE EXTRACT(year FROM checkout_time)=2018
GROUP BY tp.patron
ORDER BY tp.patron;

CREATE VIEW Patron2019checkouts AS
SELECT DISTINCT tp.patron AS patron, COUNT(*) AS num_checkout_2019
FROM Checkout c RIGHT JOIN TargetPatrons tp ON c.patron=tp.patron
WHERE EXTRACT(year FROM checkout_time)=2019
GROUP BY tp.patron
ORDER BY tp.patron;

CREATE VIEW Decline AS
SELECT DISTINCT patron, (c18.num_checkout_2018 - c19.num_checkout_2019) AS decline
FROM Patron2018checkouts c18 NATURAL JOIN Patron2019checkouts c19;

                              
-- missed (num_month_2019_no_checkouts = 12 - num_month_2019_has_checkouts) [for all targeted patron]
CREATE VIEW Missed AS
SELECT DISTINCT tp.patron AS patron, 12-COUNT(DISTINCT EXTRACT(month FROM checkout_time)) AS missed
FROM Checkout c RIGHT JOIN TargetPatrons tp ON c.patron=tp.patron
WHERE EXTRACT(year FROM checkout_time)=2019
GROUP BY tp.patron
ORDER BY tp.patron;

-- Your query that answers the question goes below the "insert into" line:
insert into q5
                                                               
SELECT e.patron AS patronID, email, usage, decline, missed
FROM Email e
    JOIN Usage u ON e.patron=u.patron
    JOIN Decline d ON u.patron=d.patron
    JOIN Missed m ON d.patron=m.patron;
