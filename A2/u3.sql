-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS OpenSun CASCADE;
DROP VIEW IF EXISTS ClosedSun CASCADE;
DROP VIEW IF EXISTS WeekPast6 CASCADE;
DROP VIEW IF EXISTS BranchCared CASCADE;
DROP VIEW IF EXISTS haveThu CASCADE;
DROP VIEW IF EXISTS notOpenOnThu CASCADE;


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.

create view OpenSun as
select distinct library
from libraryHours
where day = week_day 'sun';

create view ClosedSun as
(select library from LibraryHours) except (select * from OpenSun);

create view WeekPast6 as
select distinct library
from LibraryHours
where end_time > time '18:00:00' and (day = week_day 'mon' or day = week_day 'tue' or day = week_day 'wed' or day = week_day 'thu' or day = week_day 'fri');

create view BranchCared as
(select * from ClosedSun) except (select * from WeekPast6);

create view haveThu as
select library
from branchCared join libraryHours using (library)
where day = week_day 'thu';

create view notOpenOnThu as
(select * from branchCared) except (select * from haveThu);

Insert into libraryHours
select library, week_day 'thu' as day, time '18:00:00' as start_time, time '21:00:00' as end_time
from notOpenOnThu;

update libraryHours
set end_time = time '21:00:00'
where day = 'thu' and library in (select * from branchCared);
