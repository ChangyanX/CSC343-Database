-- Explorers Contest

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20)
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS EventWard CASCADE;


-- Define views for your intermediate steps here:
create view EventWard as 
select LibraryEvent.id as event, LibraryBranch.ward,extract(year from Eventschedule.edate) as year
from LibraryEvent join LibraryRoom on LibraryEvent.room = LibraryRoom.id
		  join LibraryBranch on LibraryRoom.library = LibraryBranch.code
		  join EventSchedule on EventSchedule.event = LibraryEvent.id;


-- Your query that answers the question goes below the "insert into" line:
insert into q4
select distinct EventSignUp.patron
from EventSignUp join EventWard using (event)
group by EventSignUp.patron, EventWard.year
having count(distinct ward) = (select count(id) from ward)
