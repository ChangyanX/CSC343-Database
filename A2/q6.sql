-- Devoted Fans

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20),
    devotedness INT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS SingleAuthorBook CASCADE;
DROP VIEW IF EXISTS BookWithAuthor CASCADE;
DROP VIEW IF EXISTS ActualChecked CASCADE;
DROP VIEW IF EXISTS NumBooksWritten CASCADE;
DROP VIEW IF EXISTS PatronsSatisfyCheckedPart CASCADE;
DROP VIEW IF EXISTS PatronsSatisfyChecked CASCADE;
DROP VIEW IF EXISTS PatronsSatisfyAll CASCADE;
DROP VIEW IF EXISTS AllPatrons CASCADE;
DROP VIEW IF EXISTS PatronDevotedness CASCADE;


-- Define views for your intermediate steps here:
-- books that have a single contributor
create view SingleAuthorBook as 
select holding.id as book_id
from holding join holdingContributor on holding.id=holdingCOntributor.holding
where holding.htype = 'books'
group by holding.id
having count(holdingContributor.contributor)=1;

create view BookWithAuthor as
select holdingContributor.contributor as author, SingleAuthorBook.book_id
from SingleAuthorBook join holdingContributor on SingleAuthorBook.book_id = holdingContributor.holding;

create view ActualChecked as
select distinct checkout.patron as patron, BookWithAuthor.book_id as book_id, BookWithAuthor.author as author
from BookWithAuthor join checkout on BookWithAuthor.book_id=checkout.holding;

create view NumBooksWritten as
select author, count(distinct book_id) as num_books
from BookWithAuthor
group by author;

create view PatronsSatisfyCheckedPart as
select patron, author
from ActualChecked
group by patron, author
having count(distinct book_id) >= (select num_books from NumBooksWritten 
				where ActualChecked.author = NumBooksWritten.author)-1;

create view PatronsSatisfyChecked as
select PatronsSatisfyCheckedPart.patron as patron, PatronsSatisfyCheckedPart.author author, book_id
from PatronsSatisfyCheckedPart, ActualChecked
where PatronsSatisfyCheckedPart.patron= ActualChecked.patron and PatronsSatisfyCheckedPart.author = ActualChecked.author;

create view PatronsSatisfyAll as
select review.patron as patronID, PatronsSatisfyChecked.author as author
from PatronsSatisfyChecked, review
where review.patron = PatronsSatisfyChecked.patron and review.holding=PatronsSatisfyChecked.book_id
group by review.patron, PatronsSatisfyChecked.author
having avg(review.stars)>=4;

create view AllPatrons as 
select card_number patronID from Patron;

create view PatronDevotedness as
select patronID, count(distinct author) devotedness
from PatronsSatisfyAll
group by patronID;


-- Your query that answers the question goes below the "insert into" line:
insert into q6

select AllPatrons.patronID, coalesce(PatronDevotedness.devotedness,0) devotedness from PatronDevotedness full join AllPatrons using (patronID);
