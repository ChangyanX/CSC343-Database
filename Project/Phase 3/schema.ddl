drop schema if exists projectschema cascade;
create schema projectschema;
set search_path to projectschema;

Create domain PropertyType as varchar(20) check(value in ('Apartment', 'House', 'Cabin', 'Condominium', 'Camper/RV', 'Bungalow', 'Townhouse', 'Loft', 'Boat', 'Bed & Breakfast', 'Other'));


Create domain cancellationPolicy as varchar(8) not null check(value in ('flexible', 'moderate', 'strict'));


create table HostInfo(
	host_id integer primary key,
	host_name varchar(100) not null,
	host_since date,
	host_about varchar(100000),
	host_is_superhost boolean,
	host_listings_count integer);


create table HostResponses(
	host_id integer primary key,
	avg_host_response_rate varchar(1000),
	host_response_time varchar(100000),
	foreign key (host_id) references HostInfo);


create table ListingInfo(
	listing_id integer primary key,
	host_id integer not null,
	description varchar(100000),
	transit varchar(100000),
	property_Type varchar(1000),
	room_Type varchar(1000),
	accommodates integer,
	num_bathrooms float,
	num_bedrooms integer,
	amenities varchar(100000),
	foreign key (host_id) references HostInfo);


create table NeighborhoodInfo(
	listing_id integer primary key,
	street varchar(100000),
	neighbourhood varchar(100000),
	neighbourhood_overview varchar(100000),
	foreign key (listing_id) references ListingInfo); 


create table ListingPrice(
	listing_id integer primary key,
	price Varchar(50) not null,
	weekly_price Varchar(50) ,
	monthly_price Varchar(50),
	security_deposit Varchar(50),
	cleaning_fee Varchar(50),
	guests_included integer,
	extra_people Varchar(50) not null,
	foreign key (listing_id) references ListingInfo);


create table ListingPolicy(
	listing_id integer primary key,
	minimum_nights integer not null check (minimum_nights >= 1),
	instant_bookable boolean not null,
	cancellation_Policy varchar(10000),
	foreign key (listing_id) references ListingInfo);



create table Score(
	listing_id integer primary key,
	review_scores_rating integer check (review_scores_rating >= 0 and review_scores_rating <= 100),
	review_scores_accuracy integer check (review_scores_accuracy >= 0 and review_scores_accuracy <= 10),
	review_scores_cleanliness integer check (review_scores_cleanliness >= 0 and review_scores_cleanliness <= 10),
	review_scores_checkin integer check (review_scores_checkin >= 0 and review_scores_checkin <= 10),
	review_scores_communication integer check (review_scores_communication >= 0 and review_scores_communication <= 10),
	review_scores_location integer check (review_scores_location >= 0 and review_scores_location <= 10),
	review_scores_value integer check (review_scores_value >= 0 and review_scores_value <= 10),
	foreign key (listing_id) references ListingInfo);


Create table Review(
	review_id Integer primary key,
	listing_id Integer not null,
	reviewer_id Integer not null,
	reviewer_name varchar(1000) not null,
	date Date,
	comments varchar(100000),
	foreign key (listing_id) references ListingInfo);

