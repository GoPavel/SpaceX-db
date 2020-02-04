-- Найти производителя груза
select manufacturer
from payloads
         inner join payloadbelonging p on payloads.id = p.payload_id
         inner join payloadcustomers p2 on p.customer_id = p2.id
where payloads.name = 'RatSat';

-- Найти количество грузов для каждого производителя
select manufacturer, count(*)
from payloads
         inner join payloadbelonging p on payloads.id = p.payload_id
         inner join payloadcustomers p2 on p.customer_id = p2.id
group by manufacturer;

-- найти производителя большинства грузов
select manufacturer, c
from (select manufacturer, count(*) as c
      from payloads
               inner join payloadbelonging p on payloads.id = p.payload_id
               inner join payloadcustomers p2 on p.customer_id = p2.id
      group by manufacturer) as man_cnt
         inner join
     (select max(c) m
      from (
        select manufacturer, count(*) as c
        from payloads
            inner join payloadbelonging p on payloads.id = p.payload_id
            inner join payloadcustomers p2 on p.customer_id = p2.id
       group by manufacturer
       ) as t) as max_man on c = m;

-- найти грузы, которые приналдежат конкретной миссии
select p.name, p.type
from missions
    inner join payloads p on missions.id = p.mission_id
where missions.full_name = 'Iridium NEXT';

-- найти запуски, которые имеют отношение к конкретной миссии
select l.full_name, p.name
from missions
    inner join payloads p on missions.id = p.mission_id
    inner join launches l on p.launch_id = l.id
where missions.full_name = 'Iridium NEXT';

-- найти статиска о попытка запуска для каждой ракеты
select r.name, count(case when l.launch_success then 1 end) as success,
               count(case when l.launch_success = false then 1 end) as fail,
               count(case when l.launch_success is null then 1 end) as unknown
from rockets r
    inner join launches l on r.id = l.rocker_id
                         and l.launch_success is not null
group by r.name;

-- запуски за последние два месяца
select full_name
from launches
where launches.launch_data > now() - INTERVAL '60 DAYS';