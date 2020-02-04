insert into rockets values
    (DEFAULT, true, 'SpaceX', 'United States', 'falcon9', 'Falcon 9', 549054, 22800, null);

insert into cores values
    (DEFAULT, 'B003', 'destroyed', '2010-06-04T18:45:00.000Z', 0);

insert into locations values
    (DEFAULT, 'Cape Canaveral', 'Florida', 28.5618571, -80.577366);
insert into launchpads values
    ((select id from locations where lat = '28.5618571' and lon = '-80.577366'),
     'ccafs_slc_40', 'CCAFS SLC 40', 'active', 38, 36);

insert into payloadcustomers values
    (DEFAULT, 'SpaceX', 'United States')
    on conflict DO NOTHING;

begin;
-- abort;
insert into payloads values
    (DEFAULT, 'Dragon Qualification Unit', 'Dragon Boilerplate', 0, 'SpaceX',
     (select id from payloadcustomers where name = 'SpaceX'), null, null);
insert into payloadbelonging values
    ((select id from payloads where name = 'Dragon Qualification Unit'),
     (select id from payloadcustomers where name = 'SpaceX'));
insert into missions values
    (DEFAULT, 'EE86F74', 'Commercial Resupply Services',
     (select id from payloads where name = 'Dragon Qualification Unit'));
update payloads
    set mission_id = (select id from missions where name = 'EE86F74')
    where name = 'Dragon Qualification Unit';
commit;

create or replace procedure insert_launch()
language plpgsql
as $$
declare
    new_launch_id int := 0;
begin
    new_launch_id := (select nextval('launch_id'));
    insert into launches values
        (new_launch_id, 'Falcon 9 Test Flight', '2010-06-04T18:45:00.000Z', true, '2010-03-13T00:00:00.000Z',
         (select id from rockets where name = 'falcon9'),
         (select id from launchpads where name = 'ccafs_slc_40'),
         (select id from cores where serial_id = 'B003')); -- core
    insert into launchcore values
        (new_launch_id,
         (select id from cores where serial_id = 'B003'),
         false, null, null);
    update payloads
        set launch_id = new_launch_id
    where name = 'Dragon Qualification Unit';
end $$;

call insert_launch();

begin;
delete from launches where id = 3;
commit;

select * from launches;
select * from launchpads;