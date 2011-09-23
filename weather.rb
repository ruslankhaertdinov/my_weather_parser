require "rubygems"
require 'nokogiri'
require 'open-uri'
require "cgi"
require 'httpclient'
require 'date'

class Weather

  def initialize(city)
    @city = city
  end

  def get_dates
    dates = []
    d = Date.today
    10.times do
      dates << d.strftime('%m/%d')
      d += 1
    end
    dates
  end

  def get_temperature(doc, path)
    day_temperature = []
    doc.css(path).each do |link|
      day_temperature << link.content
    end
    day_temperature
  end

  def get_precipitation(doc, path)
    precipitation = []
    doc.css(path).each do |link|
      precipitation << link.content
    end
    precipitation
  end

  def get_hash(dates, day_temperature, precipitation)
    hash = Hash.new
    dates.each_with_index do |item, index|
      hash[item] = "#{day_temperature[index]}, "+"#{precipitation[index]}"
    end
    hash
  end

  def weather_hash(temperature_path, precipitation_path)
    doc = retreive_html()
    dates = get_dates
    day_temperature = get_temperature(doc, temperature_path)
    precipitation = get_precipitation(doc, precipitation_path)
    hash = get_hash(dates, day_temperature, precipitation)
  end
end


class YandexWeather < Weather

  def retreive_html
    raw_url = "http://pogoda.yandex.ru/search/?text=#{CGI::escape(@city)}"
    location = HTTPClient.new.get(raw_url).headers['Location']
    doc = Nokogiri::HTML(open("http://pogoda.yandex.ru/#{CGI::escape(location)}"))
    doc
  end


  def get
    weather_hash('table.b-forecast-brief tr.data.day td', 'table.b-forecast-brief tr.data.precipitation td')
  end
end

class GismeteoWeather < Weather

  def retreive_html
    raw_url = "http://www.gismeteo.ru/city?gis#{Date.today.strftime('%Y%m')}=#{CGI::escape(@city)}&searchQueryData="
    location = HTTPClient.new.get(raw_url).headers['Location']
    location = location.scan(/\d/).to_s
    doc = Nokogiri::HTML(open("http://www.gismeteo.ru/city/weekly/#{location}"))
    doc
  end

  def get
    weather_hash('div.rframe.wblock.wdata div.wbshort td.temp:last-of-type', 'div.rframe.wblock.wdata div.wbshort td.cltext:nth-child(even)')
  end
end

class WeatherPrinter < Weather

  def initialize(weather_1, weather_2)
    @weather_1 = weather_1
    @weather_2 = weather_2
  end

  def print(first_p=-20, second_p=-60, third_p=0)
    puts sprintf("%#{first_p}s %#{second_p}s %s", "Data", "Yandex", "Gismeteo")
    puts "----------------------------------------------------------------------------------------"
    @weather_1.keys.sort.each do |k|
      puts sprintf("%#{first_p}s %#{second_p}s %s", k, @weather_1[k], @weather_2[k])

    end
  end
end

gismeteo_weather = GismeteoWeather.new("Набережные Челны").get # => {"07/21" => "+18, cloudly"}
yandex_weather = YandexWeather.new("Набережные Челны").get # => {"07/21" => "+18, cloudly"}
WeatherPrinter.new(yandex_weather, gismeteo_weather).print


# Дата     Yandex                         Gismeteo
# -----    --------------------------     ---------------------
# 21/07    +18, переменная облачность     +10, небольшой дождь
# 21/07    +18, переменная облачность     +10, небольшой дождь
# 21/07    +18, переменная облачность     +10, небольшой дождь