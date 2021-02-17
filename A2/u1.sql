-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- You might find this helpful for solving update 1:
-- A mapping between the day of the week and its index
DROP VIEW IF EXISTS day_of_week CASCADE;
CREATE VIEW day_of_week (day, idx) AS
SELECT * FROM (
	VALUES ('sun', 0), ('mon', 1), ('tue', 2), ('wed', 3),
	       ('thu', 4), ('fri', 5), ('sat', 6)
) AS d(day, idx);


-- Define views for your intermediate steps here, and end with a
-- INSERT, DELETE, or UPDATE statement.

DROP VIEW IF exists EventLibrary CASCADE;
create view EventLibrary as
select distinct eventSchedule.event, eventSchedule.edate, libraryHours.day, libraryHours.start_time, libraryHours.end_time
from eventSchedule join libraryEvent on eventSchedule.event = libraryEvent.id
		   join libraryRoom on libraryEvent.room = libraryRoom.id
		   join libraryHours using(library);


delete from eventSchedule
where to_char(eventSchedule.edate,'dy') not in (select cast(EventLibrary.day as text)
						from eventLibrary
						where eventSchedule.event = 								eventLibrary.event 
					and eventSchedule.edate = eventSchedule.edate)

or eventSchedule.start_time < (select EventLibrary.start_time 
				from eventLibrary 
				where eventLibrary.event = eventSchedule.event
				and eventLibrary.edate = eventSchedule.edate
			and to_char(eventSchedule.edate,'dy') = cast(EventLibrary.day as 					text))

or eventSchedule.end_time > (select EventLibrary.end_time 
				from eventLibrary 
				where eventLibrary.event = eventSchedule.event
				and eventLibrary.edate = eventSchedule.edate
				and to_char(eventSchedule.edate,'dy') 		=cast(EventLibrary.day as text));  

delete from libraryEvent
where libraryEvent.id not in (select event from EventSChedule);

delete from EventSignUp
where event not in (select id from libraryEvent);


 
