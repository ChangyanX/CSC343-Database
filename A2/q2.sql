-- Overdue Items

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

create table q2 (
    branch CHAR(5),
    email TEXT,
    title TEXT,
    overdue INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS ParkdaleBranch CASCADE;
DROP VIEW IF EXISTS ParkdaleCheckouts CASCADE;
DROP VIEW IF EXISTS booksHoldings CASCADE;
DROP VIEW IF EXISTS moviesHoldings CASCADE;
DROP VIEW IF EXISTS bookOverdue CASCADE;
DROP VIEW IF EXISTS movieOverdue CASCADE;

-- Define views for your intermediate steps here:
create view ParkdaleBranch as 
select LibraryBranch.code as branchcode
from LibraryBranch join Ward on LibraryBranch.ward = ward.id
where ward.name = 'Parkdale-High Park';

create view ParkdaleCheckouts as 
select checkout.id as checkout_id, patron.email as email, checkout.holding as holding_id,checkout.library as branchcode, checkout.checkout_time as checkout_time
from ParkdaleBranch join checkout on ParkdaleBranch.branchcode = checkout.library
		    join patron on checkout.patron = patron.card_number;

create view booksHoldings as
select id as books_id, title as books_title
from Holding
where htype= 'books' or htype = 'audiobooks';

create view moviesHoldings as
select id as movies_id, title as movies_title
from Holding where htype= 'movies' or htype= 'music' or htype='magazines and newspapers';

create view bookOverdue as 
select ParkdaleCheckouts.branchcode as branch, ParkdaleCheckouts.email as email, booksHoldings.books_title as title, current_date - date (ParkdaleCheckouts.checkout_time)-21 as overdue
from ParkdaleCheckouts join booksHoldings on ParkdaleCheckouts.holding_id=booksHoldings.books_id
where ParkdaleCheckouts.checkout_id not in (select checkout from return) and current_date - date (ParkdaleCheckouts.checkout_time) >21;

create view movieOverdue as
select ParkdaleCheckouts.branchcode as branch, ParkdaleCheckouts.email as email, moviesHoldings.movies_title as title, current_date - date 
(ParkdaleCheckouts.checkout_time)-7 as overdue
from ParkdaleCheckouts join moviesHoldings on ParkdaleCheckouts.holding_id = moviesHoldings.movies_id 
where ParkdaleCheckouts.checkout_id not in (select checkout from return) and current_date - date (ParkdaleCheckouts.checkout_time) >7;


-- Your query that answers the question goes below the "insert into" line:
insert into q2
(select * from bookOverdue) union ( select * from movieOverdue);

