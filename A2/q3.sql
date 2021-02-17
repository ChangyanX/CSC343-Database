-- Promotion

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

create domain patronCategory as varchar(10)
  check (value in ('inactive', 'reader', 'doer', 'keener'));

create table q3 (
    patronID Char(20),
    category patronCategory
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS libraryUsedEvent CASCADE;
DROP VIEW IF EXISTS libraryUsedBook CASCADE;
DROP VIEW IF EXISTS libraryUsed CASCADE;
DROP VIEW IF EXISTS totalBooks CASCADE;
DROP VIEW IF EXISTS totalBooksp CASCADE;
DROP VIEW IF EXISTS totalEvents CASCADE;
DROP VIEW IF EXISTS totalEventsp CASCADE;
DROP VIEW IF EXISTS PatronAvgBooks CASCADE;
DROP VIEW IF EXISTS checkOutRate CASCADE;
DROP VIEW IF EXISTS PatronAvgEvents CASCADE;
DROP VIEW IF EXISTS attendedRate CASCADE;
DROP VIEW IF EXISTS partPatronRes CASCADE;
DROP VIEW IF EXISTS otherPatronBooks CASCADE;
DROP VIEW IF EXISTS otherPatronEvents CASCADE;




-- Define views for your intermediate steps here:

create view libraryUsedEvent as
select e.patron, r.library as library_used
from eventSignUp e join libraryEvent l on e.event = l.id
		   join libraryRoom r on l.room = r.id;

create view libraryUsedBook as
select patron, library as library_used
from checkout;

create view libraryUsed as
(select * from libraryUsedEvent) union (select * from libraryUsedBook);

create view totalBooksP as
select patron, count(id) as total_books
from checkout 
group by patron;


create view totalBooks as
select s.card_number as patron, coalesce(p.total_books,0) as total_books
from totalBooksP p right join (select card_number from Patron) s on s.card_number = p.patron;


create view totalEventsP as
select patron, count(event) as total_events
from eventSignUp
group by patron;

create view totalEvents as
select s.card_number as patron, coalesce(p.total_events,0) as total_events
from totalEventsP p right join (select card_number from Patron) s on s.card_number = p.patron;

create view otherPatronBooks as
select distinct l.patron, t.patron as other_patron, t.total_books
from libraryUsed l join libraryUsedBook b on l.library_used = b.library_used
		  join totalbooks t on t.patron = b.patron;

create view PatronAvgBooks as
select patron, avg(total_books)
from otherPatronBooks
group by patron;

create view checkOutRate as
select p.patron as patronID, 
case when t.total_books < 0.25 * p.avg then 'low'
 when t.total_books > 0.75 * p.avg then 'high'
else null end as check_out
from patronAvgBooks p join totalBooks t on p.patron = t.patron;

create view otherPatronEvents as
select distinct l.patron, t.patron as other_patron, t.total_events
from libraryUsed l join libraryUsedEvent b on l.library_used = b.library_used
		  join totalEvents t on t.patron = b.patron;


create view PatronAvgEvents as
select patron, avg(total_events)
from otherPatronEvents
group by patron;

create view attendedRate as
select p.patron as patronID, 
case when t.total_events < 0.25 * p.avg then 'low'
 when t.total_events > 0.75 * p.avg then 'high'
else null end as attended
from patronAvgEvents p join totalEvents t on p.patron = t.patron;

create view partPatronRes as
select c.patronID,
case when (c.check_out = 'low' and a.attended='low') then 'inactive'
when (c.check_out = 'low' and a.attended='high') then 'doer'
when (c.check_out = 'high' and a.attended='low') then 'reader'
when (c.check_out = 'high' and a.attended='high') then 'keener'
else null end as category
from checkoutRate c join attendedRate a using (patronID);


-- Your query that answers the question goes below the "insert into" line:
insert into q3
select distinct c.card_number as patronID, p.category
from partPatronRes p right join (select card_number from Patron) c on p.patronID = c.card_number;
