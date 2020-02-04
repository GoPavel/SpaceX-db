-- cascade deleting

create or replace function func_trigger_delete_launch_core()
    returns trigger
    language plpgsql as
$$
begin
    delete from LaunchCore where launch_id = old.id;
    return null;
end;
$$;

create trigger trigger_delete_launch_core
    after delete
    on Launches
    for each row
execute function func_trigger_delete_launch_core();

-- audit of attempts

create or replace function inc_lunch_attempts_after_insert_launch()
    returns trigger
    language plpgsql as
$$
begin
    update launchpads
    set attempted_launches = attempted_launches + 1
    where id = new.launch_pad_id;
    if new.launch_success then
        update launchpads
        set successful_launches = successful_launches + 1
        where id = new.launch_pad_id;
    end if;
    return null;
end;
$$;

create or replace function dec_lunch_attempts_after_insert_launch()
    returns trigger
    language plpgsql as
$$
begin
    update launchpads
    set attempted_launches = attempted_launches - 1
    where id = old.launch_pad_id;
    if old.launch_success then
        update launchpads
        set successful_launches = successful_launches - 1
        where id = old.launch_pad_id;
    end if;
    return new;
end;
$$;

create or replace function update_launch_attempts_after_update_success_launch()
    returns trigger
    language plpgsql as
$$
declare
    diff_attempt      int := 0;
    diff_succ_attempt int := 0;
begin
    if old.launch_success is null then
        diff_attempt := 1;
    elseif new.launch_success is null then
        diff_attempt := -1;
    end if;
    update launchpads
    set attempted_launches = attempted_launches + diff_attempt
    where id = new.launch_pad_id;

    if new.launch_success = true then
        diff_succ_attempt := 1;
    elseif new.launch_success = false then
        diff_succ_attempt := -1;
    end if;

    if old.launch_success = true then
        diff_succ_attempt := diff_succ_attempt - 1;
    elseif old.launch_success = false then
        diff_succ_attempt := diff_succ_attempt + 1;
    end if;

    update launchpads
    set successful_launches = successful_launches + diff_succ_attempt
    where id = new.launch_pad_id;
    return new;
end;
$$;

create trigger trigger_inc_launch_attempts_after_insert_launch
    after insert
    on launches
    for each row
    when (new.launch_data < now() and new.launch_success is not null)
execute function inc_lunch_attempts_after_insert_launch();

create trigger trigger_dec_launch_attempts_after_delete_launch
    after delete
    on launches
    for each row
    when (old.launch_data < now() and old.launch_success is not null)
execute function dec_lunch_attempts_after_insert_launch();

create trigger trigger_inc_launch_attempts_after_update_launch
    after update
    on launches
    for each row
    when (new.launch_data < now() and new.launch_success <> old.launch_success)
execute function update_launch_attempts_after_update_success_launch();

-- check location

create or replace function check_location_reason()
    returns trigger
    language plpgsql as
$$
begin
    if not EXISTS(select *
                  from launches
                  where id = new.id) and
       not EXISTS(select *
                  from landingpads
                  where id = new.id) then
        raise exception 'Location without bindings';
    end if;
    return new;
end ;
$$;

-- create trigger trigger_check_location_reason
--     after insert on locations
--     initially deferred
--     for each row
--     execute function check_location_reason();