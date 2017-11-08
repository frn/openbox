import datetime
import json
import os
import pickle
import sys
from collections import OrderedDict
from datetime import datetime, timedelta
from os.path import join

import httplib2


class WeatherBit(object):
    _CACHE_HOURS = 1
    _key = ''
    _weatherUrl = 'http://api.weatherbit.io/v2.0'
    _currentWeather = _weatherUrl + '/current'
    _cacheFile = join(os.getenv("HOME"), '.weatherbit.cache')
    _keyFile = join(os.getenv("HOME"), '.weatherbit')
    _content = ''
    _cache = {}
    _facts = ['temp', 'description', 'wind_cdir', 'wind_spd', 'sunset', 'sunrise', 'clouds']
    _translations = {'temp': 'Temperature', 'description': 'Description', 'wind_cdir': 'Wind', 'wind_spd': 'Wind Speed',
                     'sunset': 'Sunset', 'sunrise': 'Sunrise', 'clouds': 'Clouds'}
    _factsDir = OrderedDict()
    _menu_string = ''
    city = ''
    lang = 'en'

    def get_dev_key(self):
        try:
            key_file = open(self._keyFile, 'r')
        except Exception:
            print('There is a problem with reading ofdeveloper key')
            raise
        else:
            with key_file:
                self._key = key_file.read().strip('\n')

    def get_weather(self):
        self.get_dev_key()
        params_dict = {'lang': self.lang, 'city': self.city, 'key': self._key}
        params = '&'.join([key + '=' + value for key, value in params_dict.items()])
        _, content = httplib2.Http().request(self._currentWeather + '?' + params)
        self._content = json.loads(content)['data'][0]

    def set_facts(self):
        self.get_weather()
        for fact in self._facts:
            if fact == 'description':
                self._factsDir[self._translations[fact]] = self._content['weather'][fact]
            else:
                self._factsDir[self._translations[fact]] = self._content[fact]

    def generate_menu(self):
        self.read_cache()
        if not self._cache or self.city not in self._cache or self.outdated_cache():
            self.set_facts()
            self._menu_string = '<openbox_pipe_menu>\n'
            self._menu_string += '\t<separator label="%s" />\n' % self.city
            for fact, value in self._factsDir.items():
                self._menu_string += '\t\t<item label="%s: %s"/>\n' % (fact, value)
            self._menu_string += '</openbox_pipe_menu>\n'
            self.write_cache()
        else:
            self._menu_string = self._cache[self.city]['ob_pipe_menu']

    def outdated_cache(self):
        return self._cache[self.city]['date'] + timedelta(hours=self._CACHE_HOURS) < datetime.utcnow()

    def write_cache(self):
        try:
            self._cache[self.city] = {'date': datetime.utcnow(), 'ob_pipe_menu': self._menu_string}
            cache_file = open(self._cacheFile, 'wb')
        except Exception:
            print('There is a problem with writing cache file')
            raise
        else:
            with cache_file:
                pickle.dump(self._cache, cache_file, -1)

    def read_cache(self):
        try:
            cache_file = open(self._cacheFile, 'rb')
        except EnvironmentError:
            self._cache = {}
        else:
            with cache_file:
                self._cache = pickle.load(cache_file)

    def __init__(self, city):
        self.city = city
        self.generate_menu()

    @property
    def menu_string(self):
        return self._menu_string


if __name__ == '__main__':
    if len(sys.argv) <= 1:
        print('No chosen city')
        exit(1)
    weather_bit = WeatherBit(sys.argv[1])
    print(weather_bit.menu_string)
