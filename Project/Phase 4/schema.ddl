drop schema if exists projectschema cascade;
create schema projectschema;
set search_path to projectschema;



create domain scoresRating as int
check (value >= 0 and value<=10);

create domain scoresAccuracy as int
check (value >= 0 and value<=10);

create domain scoresCleanliness as int
check (value >= 0 and value<=10);

create domain scoresCheckin as int
check (value >= 0 and value<=10);

create domain scoresCommunication as int
check (value >= 0 and value<=10);

create domain scoresLocation as int
check (value >= 0 and value<=10);

create domain scoresValue as int
check (value >= 0 and value<=10);


-- information about the host
create table HostInfo(
--id of the host
	host_id integer primary key,
--name of the host
	host_name varchar(100) not null,
--start date of the host
	host_since date,
--self introduction from the host
	host_about varchar(100000),
--whether this host has a superhost badge
	host_is_superhost boolean,
--the number of listings this host has
	host_listings_count integer);

--information about host responses
create table HostResponses(
--id of the host
	host_id integer primary key,
--the average time it takes for the host to respond
	avg_host_response_rate varchar(1000),
-- this host reponds to potential customers how much percentage of the time
	host_response_time varchar(100000),
	foreign key (host_id) references HostInfo);

--information about the listing
create table ListingInfo(
--id of the listing
	listing_id integer primary key,
--id of the host
	host_id integer not null,
--description about the listing
	description varchar(100000),
--transit information about the listing
	transit varchar(100000),
--the type the the property e.g.apartment, house, condo
	property_Type varchar(1000),
--the type of room customers are expected to have e.g. pricate room, entire apt 
	room_Type varchar(1000),
--the number of people the listing can accomodate
	accommodates integer,
--the number of bathrooms the listing has
	num_bathrooms float,
--the number of bedrooms the listing has
	num_bedrooms integer,
--the amenities provided e.g. TV, air-conditioning
	amenities varchar(100000),
	foreign key (host_id) references HostInfo);

--information about the booking of listings
create table ListingBooking(
--id of the listing
     listing_id integer,
--every day in 2016
     L_date Date,
--whether this listing has been booked
     available boolean,
--the price this listing has been booked on this day
     daily_price Varchar(50),
     foreign key (listing_id) references ListingInfo);

--information about the neighborhood of the listing
create table NeighborhoodInfo(
--id of the listing
	listing_id integer primary key,
--name of the street
	street varchar(100000),
--name of the neighbourhood
	neighbourhood varchar(100000) not null,
--description of the neighbourhood
	neighbourhood_overview varchar(100000),
	foreign key (listing_id) references ListingInfo); 

--information about the price of the listing
create table ListingPrice(
--id of the listing
	listing_id integer primary key,
--basic daily price of the listing
	price Varchar(50) not null,
--weekly price of the listing
	weekly_price Varchar(50),
--monethly price of the listing
	monthly_price Varchar(50),
--the amount of security deposit required
	security_deposit Varchar(50),
--the amount of cleaning fee required
	cleaning_fee Varchar(50),
--the number of guests that can be included
	guests_included integer,
--the price for an extra guest
	extra_people Varchar(50) not null,
	foreign key (listing_id) references ListingInfo);

--information about the policy regardin the listing
create table ListingPolicy(
--id of the listing
	listing_id integer primary key,
--the listing must be booked for how many number of nights
	minimum_nights integer check (minimum_nights >= 1),
--whether this instance can be booked anymore
	instant_bookable boolean,
--how strict the cancellation policy is e.g. strict, moderate, flexible
	cancellation_Policy varchar(10000),
	foreign key (listing_id) references ListingInfo);


--informatin about rating and score of the listing
create table Score(
--id of the listing
	listing_id integer primary key,
--the overall rating of the listing
	review_scores_rating scoresRating,
--represents the accuracy of the listing descriptions 
	review_scores_accuracy scoresAccuracy,
--represents how clean the listing is
	review_scores_cleanliness scoresCleanliness, 
--rating on the checkin experience
	review_scores_checkin scoresCheckin,
--rating on communication with the host
	review_scores_communication scoresCommunication,
--rating on the location of the listing
	review_scores_location scoresLocation, 
--rating on the value of the experience
	review_scores_value scoresValue, 
	foreign key (listing_id) references ListingInfo);

--information about the review of the listing
Create table Review(
--id of the review
	review_id Integer primary key,
--id of the listing
	listing_id Integer not null,
--id of the reviewer
	reviewer_id Integer not null,
--name fo the reviewer
	reviewer_name varchar(1000) not null,
--date of the review
	date Date,
--content of the review
	comments varchar(100000),
	foreign key (listing_id) references ListingInfo);

