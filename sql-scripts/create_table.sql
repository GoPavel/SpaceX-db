create table Rockets
(
    id                  serial
        primary key,
    active              boolean      not null,
    company             varchar(100) not null,
    country             varchar(50)  not null,
    name                varchar(20)  not null
        unique,
    full_name           varchar(50)  not null,
    weight              real         not null,
    leo_payload_weight  real         not null,
    mars_payload_weight real         null
);

create index rocket_company_index on Rockets using hash(company);
create index rocket_payload_weight_index on Rockets using btree(weight);

create type active_status_t as enum (
    'active',
    'retired',
    'destroyed',
    'unknown'
    );

create table Cores
(
    id              serial
        primary key,
    serial_id       varchar(10)     not null
        unique,
    status          active_status_t not null,
    original_launch timestamp,
    reuse_count     int             not null
);

create table Locations
(
    id        serial
        primary key,
    full_name varchar(100) not null,
    region    varchar(50)  not null,
    lat       real         not null,
    lon       real         not null,
    unique (lat, lon)
);

create type landing_type_t as enum (
    'asds', -- Autonomous spaceport drone ship
    'rtls' -- Return to Launch Site
    );
--
-- select *
-- from landingpads
--     inner join Locations L on LandingPads.id = L.id
--     ;

create table LandingPads
(
    id                  int
        primary key
        references Locations (id) on delete cascade,
    name                varchar(20)     not null
        unique,
    full_name           varchar(50)     not null,
    status              active_status_t not null,
    landing_type        landing_type_t  not null,
    attempted_landings  int             not null,
    -- TODO add default 0
    successful_landings int             not null,
    check (attempted_landings >= successful_landings)
);

create view LandingPadsWithLocation as
    select L.id, LP.name, LP.full_name, LP.status, LP.landing_type,
           LP.attempted_landings, LP.successful_landings,
           L.full_name as location_name, L.region,
           L.lat, L.lon
    from LandingPads LP inner join Locations L on LP.id = L.id;

-- select * from LandingPadsWithLocation;

create table LaunchPads
(
    id                  int
        primary key
        references Locations (id) on delete cascade,
    name                varchar(20)     not null
        unique,
    full_name           varchar(50)     not null,
    status              active_status_t not null,
    attempted_launches  int             not null,
    successful_launches int             not null
    check (attempted_launches >= successful_launches)
);

create view LaunchPadsWithLocation as
    select L.id, LP.name, LP.full_name, LP.status,
           LP.attempted_launches, LP.successful_launches,
           L.full_name as location_name, L.region,
           L.lat, L.lon
    from LaunchPads LP inner join Locations L on LP.id = L.id;


create table PayloadCustomers
(
    id          serial
        primary key,
    name        varchar(50) not null
        unique,
    nationality varchar(50) null
);

create table Missions
(
    id              serial
        primary key,
    name            varchar(20)  not null
        unique,
    full_name       varchar(100) not null,
    some_payload_id int          not null
    -- references Payloads (id)
);

create table Payloads
(
    id               serial
        primary key,
    name             varchar(50)  not null
        unique,
    type             varchar(50)  not null,
    weight           real         not null,
    manufacturer     varchar(100) not null,
    some_customer_id int          not null,
    mission_id       int          null
        references Missions (id),
    launch_id        int          null
    -- references Launches (id),

--     foreign key (id, some_customer_id)
--         references PayloadBelonging (payload_id, customer_id)
);

create index payload_weight_index on Payloads using btree(weight);

alter table Missions
    add foreign key (some_payload_id)
        references Payloads (id)
        deferrable initially deferred
;

create table PayloadBelonging
(
    payload_id  int not null
        references Payloads (id),
    customer_id int not null
        references PayloadCustomers (id),

    primary key (payload_id, customer_id)
);

alter table Payloads
    add foreign key (id, some_customer_id)
        references PayloadBelonging (payload_id, customer_id)
        deferrable initially deferred
;

create sequence launch_id start 1;

create table Launches
(
    id               int
        primary key,
    full_name        varchar(100) not null
        unique,
    launch_data      timestamp    not null,
    launch_success   bool         null,
    static_fire_date timestamp    null,
    rocker_id        int          not null
        references Rockets (id),
    launch_pad_id    int          not null
        references LaunchPads (id),
    some_core_id     int          not null

--     foreign key (id, some_core_id)
--         references LaunchCore (launch_id, core_id)
    check (static_fire_date is null or launch_data > static_fire_date)
);

create index launch_data_index on Launches using btree(launch_data);

alter table Payloads
    add foreign key (launch_id)
        references Launches (id)
;

create table LaunchCore
(
    launch_id      int  not null
        references Launches (id)
            deferrable initially deferred,
    core_id        int  not null
        references Cores (id),
    land_intent    bool not null,
    land_success   bool null,
    landing_pad_id int  null
        references LandingPads (id),

    primary key (launch_id, core_id)
);

alter table Launches
    add foreign key (id, some_core_id)
        references LaunchCore (launch_id, core_id)
        deferrable initially deferred
;
