import datetime
import json
import os
import pickle
import sys
import urllib
from collections import OrderedDict
from datetime import datetime, timedelta
from os.path import join

import httplib2


class WeatherBit(object):
    CACHE_HOURS = 1
    weatherUrl = 'http://api.weatherbit.io/v2.0'
    currentWeather = weatherUrl + '/current'
    cache_file = join(os.getenv("HOME"), '.weatherbit.cache')
    key_file = join(os.getenv("HOME"), '.weatherbit')
    city = 'Wroclaw'
    _lang = 'en'
    _key = ''
    http = httplib2.Http()
    content = ''
    menu_string = ''
    cache = {}
    facts = ['temp', 'description', 'wind_cdir', 'sunset', 'sunrise', 'clouds']
    translations = {'temp': 'Temperature', 'description': 'Description', 'wind_cdir': 'Wind', 'sunset': 'Sunset',
                    'sunrise': 'Sunrise', 'clouds': 'Clouds'}
    factsDir = OrderedDict()

    def get_dev_key(self):
        self._key = open(self.key_file, 'r').read().strip('\n')

    def set_city(self, city):
        self.city = city
        return self

    def get_weather(self):
        params_dict = {'lang': self._lang, 'city': self.city, 'key': self._key}
        params = urllib.urlencode(params_dict)
        resp, content = self.http.request(self.currentWeather + '?' + params)
        self.content = json.loads(content)['data'][0]

    def set_facts(self):
        self.get_weather()
        for fact in self.facts:
            if fact == 'description':
                self.factsDir[self.translations[fact]] = self.content['weather'][fact]
            else:
                self.factsDir[self.translations[fact]] = self.content[fact]

    def __init__(self, city):
        self.get_dev_key()
        self.set_city(city)
        self.generate_menu()

    def generate_menu(self):
        self.read_cache()
        if not self.cache or self.city not in self.cache or (
                        self.cache[self.city]['date'] + timedelta(hours=self.CACHE_HOURS) < datetime.utcnow()):
            self.set_facts()
            self.menu_string = ' <openbox_pipe_menu>\n'
            self.menu_string += '\t<separator label = "%s" />\n' % self.city
            for fact, value in self.factsDir.iteritems():
                self.menu_string += '\t\t<item label="%s: %s"/>\n' % (fact, value)
            self.menu_string += ' </openbox_pipe_menu>\n'
            self.write_cache()
        else:
            self.menu_string = self.cache[self.city]['ob_pipe_menu']

    def write_cache(self):
        try:
            self.cache[self.city] = {'date': datetime.utcnow(), 'ob_pipe_menu': self.menu_string}
            f = open(self.cache_file, 'wb')
            pickle.dump(self.cache, f, -1)
            f.close()
        except IOError:
            raise

    def read_cache(self):
        try:
            f = open(self.cache_file, 'rb')
            self.cache = pickle.load(f)
            f.close()
        except IOError:
            self.cache = {}


if __name__ == '__main__':
    if len(sys.argv) < 1:
        print('No chosen city')
        exit(1)
    print (WeatherBit(sys.argv[1]).menu_string)
