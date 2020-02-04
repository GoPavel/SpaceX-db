import asyncio
import contextlib
import logging
import os
import sys

import aiohttp
import asyncpg

from model import Rocket, Core, LaunchPad, LandingPad, Payload, Mission, Launch

logger = logging.getLogger(__name__)


async def fit(fitter, path):
    async with aiohttp.ClientSession() as session:
        async with session.get(path) as response:
            json = await response.json()
    print(f'length of results: {len(json)}')
    print(f'ex: {json[0]}')

    async with contextlib.AsyncExitStack() as astack:
        conn = await asyncpg.connect(user='gopavel', password='1234', database='spacex', host='127.0.0.1')
        astack.push_async_callback(conn.close)
        acc = 0
        for inst in json:
            try:
                await fitter(conn, inst)
            except Exception as e:
                logger.warning("I want sleep!", exc_info=e)
            else:
                acc += 1
        print(f'Success: {acc}/{len(json)}')
    print(f'ex: {json[0]}')


async def fit_rockets(conn, inst):
    i = Rocket(inst)
    await conn.fetch(
        f'''
        insert into rockets values
        (DEFAULT, {i.active!r}, {i.company!r}, {i.country!r}, {i.name!r}, {i.fullname!r}, {i.weight}, {i.leo}, {i.mars})
        '''
    )


async def fit_cores(conn, inst):
    i = Core(inst)
    await conn.fetch(
        f'''
        insert into cores values
        (DEFAULT, {i.serial_id!r}, {i.status!r}, {i.orig!r}, {i.reuse_count!r})
        '''
    )


async def fit_launch_pads(conn, inst):
    i = LaunchPad(inst)
    await conn.fetch(
        f'''
        insert into locations values
        (DEFAULT, {i.loc_fullname!r}, {i.loc_region!r}, {i.loc_lat}, {i.loc_lon}) 
        '''
    )
    await conn.fetch(
        f'''
        insert into launchpads values
        ((select id from locations where lat = '{i.loc_lat}' and lon = '{i.loc_lon}'), 
            {i.name!r}, {i.fullname!r}, {i.status!r}, {i.att_launch!r}, {i.succ_launch!r})
        '''
    )


async def fit_landing_pads(conn, inst):
    i = LandingPad(inst)
    try:
        await conn.fetch(
            f'''
            insert into locations values
            (DEFAULT, {i.loc_fullname!r}, {i.loc_region!r}, {i.loc_lat}, {i.loc_lon}) 
            '''
        )
    except Exception:
        pass
    await conn.fetch(
        f'''
        insert into landingpads values
        ((select id from locations where lat = '{i.loc_lat}' and lon = '{i.loc_lon}'),
            {i.name!r}, {i.fullname!r}, {i.status!r}, {i.landtype!r}, {i.att_landing!r}, {i.succ_landing!r})
        '''
    )


async def fit_payload_without_mission(conn, inst):
    i = Payload(inst)
    try:
        await conn.fetch('begin;')
        for cust in i.customers:
            await conn.fetch(f'''
                insert into payloadcustomers values (DEFAULT, {cust!r}, {i.nat!r})
                on conflict DO NOTHING;
            ''')
        await conn.fetch(f'''
            insert into payloads values
            (DEFAULT, {i.name!r}, {i.type!r}, {i.weight}, {i.man!r},
             (select id from payloadcustomers where name = {i.customers[0]!r}), null, null);
        ''')
        for cust in i.customers:
            await conn.fetch(f'''
                insert into payloadbelonging values
                    ((select id from payloads where name = {i.name!r}),
                     (select id from payloadcustomers where name = {cust!r}));
            ''')
    except Exception:
        await conn.fetch('abort;')
        raise
    else:
        await conn.fetch('commit;')


async def fit_mission(conn, inst):
    i = Mission(inst)
    try:
        await conn.fetch('begin;')
        await conn.fetch(f'''
            insert into missions values
              (DEFAULT, {i.name!r}, {i.fullname!r}, 
                (select id from payloads where name = {i.payloads[0]!r}))
        ''')
        for pid in i.payloads:
            await conn.fetch(f'''
                update payloads
                    set mission_id = (select id from missions where name = {i.name!r})
                where name = {pid!r};
            ''')
    except Exception:
        await conn.fetch('abort;')
        raise
    else:
        await conn.fetch('commit;')


async def fit_launches(conn, inst):
    i = Launch(inst)
    if len(i.cores) == 1:
        await conn.fetch(f'''
            call insert_launch_with_one_core( 
               {i.fullname!r}, {i.launch_date!r}, {i.launch_success}, {i.static_fire_date!r},
                {i.rocket!r}, {i.launchpad!r}, 
                {i.cores[0].landing_intent}, 
                {i.cores[0].serial!r}, 
                {i.cores[0].landing_success},
                {i.cores[0].landingpad_name}
            );
        ''')
    elif len(i.cores) == 3:
        await conn.fetch(f'''
            call insert_launch_with_tree_core(
               {i.fullname!r}, {i.launch_date!r}, {i.launch_success}, {i.static_fire_date!r},
                {i.rocket!r}, {i.launchpad!r}, 
                {i.cores[0].landing_intent},
                {i.cores[0].serial!r}, 
                {i.cores[1].serial!r}, 
                {i.cores[2].serial!r}, 
                {i.cores[0].landingpad_name},
                {i.cores[1].landingpad_name},
                {i.cores[2].landingpad_name},
                {i.cores[0].landing_success},
                {i.cores[1].landing_success},
                {i.cores[2].landing_success}
            );
        ''')
    for payload in i.payloads:
        await conn.fetch(f'''
            call add_payload_for_leo({i.fullname!r}, {payload!r});
        ''')


async def main():
    await fit(fit_rockets, 'https://api.spacexdata.com/v3/rockets')
    await fit(fit_cores, 'https://api.spacexdata.com/v3/cores')
    await fit(fit_launch_pads, 'https://api.spacexdata.com/v3/launchpads')
    await fit(fit_landing_pads, 'https://api.spacexdata.com/v3/landpads')
    await fit(fit_payload_without_mission, 'https://api.spacexdata.com/v3/payloads')
    await fit(fit_mission, 'https://api.spacexdata.com/v3/missions')
    await fit(fit_launches, 'https://api.spacexdata.com/v3/launches')


if __name__ == '__main__':
    logging.basicConfig(level=logging.WARNING, stream=sys.stdout)
    asyncio.run(main())
