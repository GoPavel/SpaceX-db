create or replace procedure insert_launch_with_one_core(full_name varchar(100), launch_data timestamp,
                                                        launch_success bool, static_fire_date timestamp,
                                                        rocket_name varchar(20), launchpad_name varchar(20),
                                                        landing_intent bool,
                                                        core_serial varchar(20),
                                                        landing_success bool default null,
                                                        landing_pad_name varchar(20) default null)
    language plpgsql
as
$$
declare
    new_launch_id int := 0;
begin
    new_launch_id := (select nextval('launch_id'));
    insert into launches
    values (new_launch_id, full_name, launch_data, launch_success, static_fire_date,
            (select id from rockets where name = rocket_name),
            (select id from launchpads where name = launchpad_name),
            (select id from cores where serial_id = core_serial));
    insert into launchcore
    values (new_launch_id, (select id from cores where serial_id = core_serial),
            landing_intent, landing_success, (select id from landingpads where name = landing_pad_name));
end
$$;

create or replace procedure insert_launch_with_tree_core(full_name varchar(100), launch_data timestamp,
                                                         launch_success bool, static_fire_date timestamp,
                                                         rocket_name varchar(20), launchpad_name varchar(20),
                                                         landing_intent bool,
    core_serial1 varchar(20), core_serial2 varchar(20), core_serial3 varchar(20),
    landing_success1 bool default null, landing_success2 bool default null, landing_success3 bool default null,
    landing_pad_name1 varchar(20) default null, landing_pad_name2 varchar(20) default null, landing_pad_name3 varchar(20) default null)
    language plpgsql
as
$$
declare
    new_launch_id int := 0;
begin
    new_launch_id := (select nextval('launch_id'));
    insert into launches
    values (new_launch_id, full_name, launch_data, launch_success, static_fire_date,
            (select id from rockets where name = rocket_name),
            (select id from launchpads where name = launchpad_name),
            (select id from cores where serial_id = core_serial1));
    insert into launchcore
    values (new_launch_id, (select id from cores where serial_id = core_serial1),
            landing_intent, landing_success1, (select id from landingpads where name = landing_pad_name1)),
           (new_launch_id, (select id from cores where serial_id = core_serial2),
            landing_intent, landing_success2, (select id from landingpads where name = landing_pad_name2)),
           (new_launch_id, (select id from cores where serial_id = core_serial3),
            landing_intent, landing_success3, (select id from landingpads where name = landing_pad_name3));
end
$$;

create or replace procedure add_payload_for_leo(launch_name varchar(100), payload_name varchar(50))
    language plpgsql
as
$$
declare
    bound   int;
    current int;
begin
    current := (select sum(p.weight)
                from launches
                         inner join payloads p on launches.id = p.launch_id
                where full_name = launch_name
                group by full_name);
    bound := (select r.leo_payload_weight
              from launches
                       inner join rockets r on launches.rocker_id = r.id
              where launches.full_name = launch_name);
    current = current + (select weight from payloads where name = payload_name);
    if current > bound then
        raise exception 'Too many payload!!!';
    end if;
    update payloads
    set launch_id = (select id from launches where full_name = launch_name)
    where name = payload_name;
end
$$;
