drop schema if exists projectschema cascade; 
create schema projectschema; 
set search_path to projectschema;

Create domain PropertyType as varchar(20)
	check  (value in ('Apartment', 'House', 'Cabin', 'Condominium', 'Camper/RV', 'Bungalow', 'Townhouse', 'Loft', 'Boat', 'Bed & Breakfast', 'Other'));


Create domain RoomType as varchar(20)
	check (value in ('Private room', 'Entire home/apt'));

Create domain cancellationPolicy as varchar(8) not null check(value in ('flexible', 'moderate', 'strict'));


create table HostInfo(
	host_id integer primary key,
	host_name varchar(20) not null,
	host_is_superhost boolean,
	host_listings_count integer,
	host_since date);

create table HostResponses(
	host_id integer primary key,
	avg_host_response_rate integer,
	host_response_time varchar(20),
	foreign key (host_id) references HostInfo);

create table ListingInfo(
	listing_id integer primary key,
	host_id integer not null,
	description varchar(255),
	transit varchar(255),
	property_Type Propertytype,
	room_Type Roomtype,
	accommodates integer,
	num_bedrooms integer,
	num_bathrooms integer,
	amenities varchar(255),
	foreign key (host_id) references HostInfo);

create table NeighborhoodInfo(
	listing_id integer primary key,
	street varchar(30),
	neighbourhood varchar(20),
	neighbourhood_overview varchar(50),
	foreign key (listing_id) references ListingInfo); 

create table ListingPrice(
	listing_id integer primary key,
	price integer not null check (price >= 0),
	weekly_price integer check (weekly_price >= 0),
	monthly_price integer check (monthly_price >= 0),
	security_deposit integer check (security_deposit >= 0), 
	cleaning_fee integer check (cleaning_fee >= 0),
	guests_included integer check (guests_included >= 0),
	extra_people integer not null check (extra_people >= 0), 
	foreign key (listing_id) references ListingInfo);

create table ListingPolicy(
	listing_id integer primary key,
	minimum_nights integer not null check (minimum_nights >= 1),
	instant_bookable integer not null,
	cancellation_Policy cancellationpolicy, 
	foreign key (listing_id) references ListingInfo);

create table Score(
	listing_id integer primary key,
	review_scores_rating integer check (review_scores_rating >= 0 and review_scores_rating <= 10),
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
	reviewer_name varchar(30) not null, 
	date Date,
	comments varchar(200),
	foreign key (listing_id) references ListingInfo);
