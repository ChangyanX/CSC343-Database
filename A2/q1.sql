-- Branch Activity

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5),
    year INT,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


DROP VIEW IF EXISTS avg_duration_perBranch_perYear CASCADE;
DROP VIEW IF EXISTS checkouts_and_returned_perBranch_perYear CASCADE;
DROP VIEW IF EXISTS tot_duration_perBranch_perYear CASCADE;
DROP VIEW IF EXISTS durations_btw_checkout_return CASCADE;
DROP VIEW IF EXISTS checkouts_perBranch_perYear CASCADE;
DROP VIEW IF EXISTS registration_PerBranch_perYear CASCADE;
DROP VIEW IF EXISTS sessions_PerBranch_perYear CASCADE;
DROP VIEW IF EXISTS events_PerBranch_perYear CASCADE;
DROP VIEW IF EXISTS basic CASCADE;
DROP TABLE IF EXISTS TargetYears CASCADE;

-- Define views for your intermediate steps here:


-- BRANCH, YEAR
CREATE TABLE TargetYears
(year INT check (year >=2015 AND year <= 2019));

INSERT INTO TargetYears VALUES (2015), (2016), (2017), (2018), (2019);

CREATE VIEW basic AS
SELECT code AS branch, year
FROM LibraryBranch, TargetYears
ORDER BY code, year;


-- EVENTS: The number of events for each branch each year
CREATE VIEW events_PerBranch_perYear AS
SELECT lr.library AS branch, EXTRACT(year FROM es.edate) AS year, COUNT(DISTINCT es.event) AS events
FROM LibraryRoom lr
JOIN LibraryEvent le ON lr.id=le.room
JOIN EventSchedule es ON le.id=es.event
GROUP BY lr.library, EXTRACT(year FROM es.edate);

-- SESSIONS: The average number of sessions per event, across all events at that branch during that year.
CREATE VIEW sessions_PerBranch_perYear AS
SELECT lr.library AS branch, EXTRACT(year FROM es.edate) AS year, 
CASE
    WHEN COUNT(DISTINCT es.event)=0 THEN 0
    ELSE COUNT(es.event)::FLOAT / COUNT(DISTINCT es.event)::FLOAT
END AS sessions
FROM LibraryRoom lr
JOIN LibraryEvent le ON lr.id=le.room
JOIN EventSchedule es ON le.id=es.event
GROUP BY lr.library, EXTRACT(year FROM es.edate);

-- REGISTRATION: The sum of the num of distinct patrons for each event -- each year, each branch
CREATE VIEW patronNum_perEvent AS
SELECT lr.library AS branch, EXTRACT(year FROM es.edate) AS year, 
		 esp.event AS event, COUNT(DISTINCT patron) AS num_patron
FROM EventSignUp esp 
	JOIN EventSchedule es ON esp.event=es.event
	JOIN LibraryEvent le ON le.id= esp.event
	JOIN LibraryRoom lr ON lr.id=le.room
GROUP BY lr.library, EXTRACT(year FROM es.edate), esp.event 
ORDER BY lr.library, EXTRACT(year FROM es.edate);

		 
CREATE VIEW registration_PerBranch_perYear AS
SELECT branch, year, SUM(num_patron) AS registration
FROM patronNum_perEvent pn
GROUP BY branch, year
ORDER BY branch, year;	 

-- HOLDINGS: The total number of holdings including its copies of a branch
CREATE VIEW holdings_PerBranch AS
SELECT library AS branch, SUM(num_holdings) AS holdings
FROM LibraryCatalogue
GROUP BY library;
		 
CREATE VIEW holdings_PerBranch_perYear AS
SELECT branch, year, holdings
FROM holdings_PerBranch, TargetYears
ORDER BY branch, year;

-- CHECKOUTS: The number of checkouts for each branch each year
CREATE VIEW checkouts_perBranch_perYear AS
SELECT library AS branch, EXTRACT(year FROM checkout_time) AS year, COUNT(id) AS checkouts
FROM checkout
GROUP BY library, EXTRACT(year FROM checkout_time);

-- DURATION: The checkout library, checkout year, duration between checkout and return
		 
-- CREATE VIEW duration_perBranch_perYear AS
-- SELECT Checkout.library AS branch, EXTRACT(year FROM Checkout.checkout_time) AS year, 
-- CASE
-- 	WHEN COUNT(*)=0 THEN 0
-- 	ELSE DATE_PART('day', checkout_time::timestamp - return_time::timestamp) 
-- END AS duration
-- FROM Checkout RIGHT JOIN Return ON Checkout.id=Return.checkout
-- GROUP BY Checkout.library, EXTRACT(year FROM Checkout.checkout_time);
		 
CREATE VIEW durations_btw_checkout_return AS
SELECT library AS branch, EXTRACT(year FROM checkout_time) AS year, 
return_time::date - checkout_time::date AS days
FROM Checkout JOIN Return ON Checkout.id=Return.checkout
ORDER BY Checkout.library, EXTRACT(year FROM checkout_time);

CREATE VIEW tot_duration_perBranch_perYear AS
SELECT branch, year, SUM(days) AS tot_days
FROM durations_btw_checkout_return
GROUP BY branch, year
ORDER BY branch, year;
		 
CREATE VIEW checkouts_and_returned_perBranch_perYear AS
SELECT library AS branch, EXTRACT(year FROM checkout_time) AS year, COUNT(id) AS checkouts
FROM Checkout JOIN Return ON Checkout.id=Return.checkout
GROUP BY library, EXTRACT(year FROM checkout_time);

CREATE VIEW avg_duration_perBranch_perYear AS
SELECT t.branch, t.year, 
CASE
	WHEN c.checkouts IS NULL THEN 0
	ELSE (tot_days::FLOAT / c.checkouts::FLOAT)
END AS duration
FROM tot_duration_perBranch_perYear t JOIN checkouts_and_returned_perBranch_perYear c
ON t.branch = c.branch AND t.year=c.year
ORDER BY branch, year;

                                          
                                          
                                          
-- Your query that answers the question goes below the "insert into" line:
insert into q1
                                          
SELECT basic.branch, basic.year, 
CASE WHEN e.events IS NULL THEN 0
     ELSE e.events
END AS events,
		 
CASE WHEN s.sessions IS NULL THEN 0
     ELSE s.sessions
END AS sessions,

CASE WHEN r.registration IS NULL THEN 0
     ELSE r.registration
END AS registration,
		 
CASE WHEN h.holdings IS NULL THEN 0
     ELSE h.holdings
END AS holdings,
		 
CASE WHEN c.checkouts IS NULL THEN 0
     ELSE c.checkouts
END AS checkouts,
		 
CASE WHEN d.duration IS NULL THEN 0
     ELSE d.duration
END AS duration
		 
FROM basic 
	LEFT JOIN events_PerBranch_perYear e 
	ON basic.branch=e.branch AND basic.year=e.year
	LEFT JOIN sessions_PerBranch_perYear s 
	ON basic.branch=s.branch AND basic.year=s.year	 
	LEFT JOIN registration_PerBranch_perYear r 
	ON basic.branch=r.branch AND basic.year=r.year
	LEFT JOIN holdings_PerBranch_perYear h
	ON basic.branch=h.branch AND basic.year=h.year	
	LEFT JOIN checkouts_PerBranch_perYear c
	ON basic.branch=c.branch AND basic.year=c.year
	LEFT JOIN avg_duration_perBranch_perYear d
	ON basic.branch=d.branch AND basic.year=d.year
;
                                          
                                          
                                          
