-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;

DROP VIEW IF EXISTS DownsviewCode CASCADE;
DROP VIEW IF EXISTS DownsviewCurrentlyOverdued CASCADE;
DROP VIEW IF EXISTS NoMoreThan5BooksCheckedOut CASCADE;
DROP VIEW IF EXISTS NoneOverdueMoreThan7d CASCADE;
DROP VIEW IF EXISTS DesiredPatrons CASCADE;


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.



-- find ‘Downsview’ branch code

-- CREATE VIEW DownsviewCode AS
-- SELECT code
-- FROM LibraryBranch
-- WHERE name='Downsview';


-- find all 
	-- currently overdued book (check-out, but not yet returned items)
 	-- (must be type ‘book’)
 	--  in Downsview
-- CREATE VIEW DownsviewCurrentlyOverdued AS
-- SELECT c.id AS checkout_id, c.patron AS patron, c.holding AS holding_id, checkout_time
-- FROM Checkout c 
-- 	INNER JOIN DownsviewCode dc ON dc.code=c.library
-- 	INNER JOIN Holding h ON h.id=c.holding
-- WHERE h.htype='books' 
-- 	    AND 
--       c.id NOT IN (SELECT checkout FROM Return);

CREATE VIEW DownsviewCurrentlyOverdued AS
SELECT c.id AS checkout_id, c.patron AS patron, c.holding AS holding_id, checkout_time
FROM Checkout c 
	INNER JOIN Holding h ON h.id=c.holding
WHERE h.htype='books' 
AND c.id NOT IN (SELECT checkout FROM Return) 
AND c.library IN (SELECT code FROM LibraryBranch WHERE name='Downsview')
AND CURRENT_DATE - DATE(c.checkout_time) > 21;
      
      

-- find patron 	
	-- has no more than 5 books checked out (<=5) and 
	-- none is overdue by more than 7 days, 
CREATE VIEW NoMoreThan5BooksCheckedOut AS
SELECT patron
FROM DownsviewCurrentlyOverdued d
GROUP BY d.patron
HAVING COUNT(checkout_id) <= 5;

CREATE VIEW NoneOverdueMoreThan7d AS -- (all checked out patrons) - (exist overdue more than 7d) 
(SELECT patron FROM DownsviewCurrentlyOverdued)
EXCEPT
(SELECT patron
FROM DownsviewCurrentlyOverdued d
WHERE EXTRACT(day FROM LOCALTIMESTAMP - checkout_time) > 7
 AND CURRENT_DATE - DATE(d.checkout_time) > 29
);




WITH DesiredPatrons AS (
	(SELECT patron FROM NoMoreThan5BooksCheckedOut) 
  	INTERSECT
  	(SELECT patron FROM NoneOverdueMoreThan7d)
)
UPDATE Checkout
SET checkout_time = checkout_time + interval '14 days'
FROM DesiredPatrons
WHERE Checkout.patron = DesiredPatrons.patron;
      
