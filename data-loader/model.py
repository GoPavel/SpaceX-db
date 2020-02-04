class Wrapper:
    def __init__(self, json):
        self.json = json


class Rocket(Wrapper):
    @property
    def active(self) -> str:
        return self.json['active']

    @property
    def company(self) -> str:
        return self.json['company']

    @property
    def country(self) -> str:
        return self.json['country']

    @property
    def name(self) -> str:
        return self.json['rocket_id']

    @property
    def fullname(self) -> str:
        return self.json['rocket_name']

    @property
    def weight(self) -> int:
        return self.json['mass']['kg']

    @property
    def leo(self) -> str:
        for w in self.json['payload_weights']:
            if w['id'] == 'leo':
                return w['kg']
        return 'null'

    @property
    def mars(self) -> str:
        for w in self.json['payload_weights']:
            if w['id'] == 'mars':
                return w['kg']
        return 'null'


class Core(Wrapper):
    @property
    def serial_id(self) -> str:
        return self.json['core_serial']

    @property
    def status(self) -> str:
        s = self.json['status']
        if s == 'inactive':
            s = 'retired'
        if s == 'lost':
            s = 'destroyed'
        return s

    @property
    def orig(self) -> str:
        return self.json['original_launch']

    @property
    def reuse_count(self) -> int:
        return self.json['reuse_count']


class WithLocation(Wrapper):
    @property
    def loc_fullname(self) -> str:
        return self.json['location']['name']

    @property
    def loc_region(self) -> str:
        return self.json['location']['region']

    @property
    def loc_lat(self) -> str:
        return self.json['location']['latitude']

    @property
    def loc_lon(self) -> str:
        return self.json['location']['longitude']


class LaunchPad(WithLocation):
    @property
    def name(self) -> str:
        return self.json['site_id']

    @property
    def fullname(self) -> str:
        return self.json['name']

    @property
    def att_launch(self) -> str:
        return self.json['attempted_launches']

    @property
    def succ_launch(self) -> str:
        return self.json['successful_launches']

    @property
    def status(self) -> str:
        return self.json['status']


class LandingPad(WithLocation):
    @property
    def name(self) -> str:
        return self.json['id']

    @property
    def fullname(self) -> str:
        return self.json['full_name']

    @property
    def att_landing(self) -> str:
        return self.json['attempted_landings']

    @property
    def succ_landing(self) -> str:
        return self.json['successful_landings']

    @property
    def status(self) -> str:
        return self.json['status']

    @property
    def landtype(self) -> str:
        return self.json['landing_type'].swapcase()


class Payload(Wrapper):
    @property
    def name(self) -> str:
        return self.json['payload_id']

    @property
    def type(self) -> str:
        return self.json['payload_type']

    @property
    def customers(self) -> str:
        return self.json['customers']

    @property
    def nat(self) -> str:
        return self.json['nationality']

    @property
    def weight(self) -> int:
        a = self.json['payload_mass_kg']
        return a if a is not None else 0

    @property
    def man(self) -> str:
        return self.json['manufacturer']


class Mission(Wrapper):
    @property
    def fullname(self) -> str:
        return self.json['mission_name']

    @property
    def name(self) -> str:
        return self.json['mission_id']

    @property
    def payloads(self) -> str:
        return self.json['payload_ids']

    # @property
    # def (self) -> str:
    #     return self.json['']


class LaunchCore(Wrapper):
    @property
    def serial(self) -> str:
        return self.json['core_serial']

    @property
    def landingpad_name(self) -> str:
        s = self.json['landing_vehicle']
        if s is not None:
            return repr(s)
        else:
            return 'null'

    @property
    def landing_success(self):
        s = self.json['land_success']
        if s is None:
            return 'null'
        elif s:
            return 'true'
        else:
            return 'false'

    @property
    def landing_intent(self):
        return self.json['landing_intent']


class Launch(Wrapper):
    @property
    def fullname(self) -> str:
        return self.json['mission_name']

    @property
    def launch_date(self) -> str:
        return self.json['launch_date_utc']

    @property
    def launch_success(self) -> str:
        s = self.json['launch_success']
        if s is None:
            return 'null'
        elif s:
            return 'true'
        else:
            return 'false'

    @property
    def static_fire_date(self) -> str:
        return self.json['static_fire_date_utc']

    @property
    def cores(self):
        return list(map(LaunchCore, self.json['rocket']['first_stage']['cores']))

    @property
    def payloads(self):
        return list(map(lambda p: p['payload_id'], self.json['rocket']['second_stage']['payloads']))

    @property
    def rocket(self) -> str:
        return self.json['rocket']['rocket_id']

    @property
    def launchpad(self) -> str:
        return self.json['launch_site']['site_id']
