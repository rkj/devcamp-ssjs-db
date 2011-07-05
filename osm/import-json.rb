#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'set'
require 'data_mapper'
require 'dm-migrations'
require 'dm-constraints'

if ARGV.size < 2
  puts "Usage: #{$PROGRAM_NAME} json_file output_file"
  exit 1
end

dbconf = YAML.load(File.read "database.yml")["local"]
DataMapper.setup(:default, dbconf)
DataMapper::Logger.new(ARGV[1], :debug)
class Category
  include DataMapper::Resource
  property :id,         Serial
  property :name, String
  property :parent_id, Integer
end

class Place
  include DataMapper::Resource
  property :id,         Serial
  property :name, String
  property :address_id, Integer
  property :category_id, Integer
  property :lon, Float
  property :lat, Float

  belongs_to :address
  belongs_to :category
end

class Address
  include DataMapper::Resource
  property :id,         Serial
  property :street, String
  property :house_no, String
  property :city, String
  property :country, String
end

class Rating
  include DataMapper::Resource
  property :id,         Serial
  property :place_id, Integer, :index => true
  property :rating, Integer
  property :email, String
  property :review, String
  property :created_at, DateTime

  belongs_to :place
end

class Premium
  include DataMapper::Resource
  property :id,         Serial
  property :place_id, Integer, :index => true
  property :provider, String
  property :hour_open, Integer
  property :hour_close, Integer
end

class Link
  include DataMapper::Resource
  property :id,         Serial
  property :place_id, Integer, :index => true
  property :url, String
end

DataMapper.finalize
DataMapper.auto_upgrade!
exit 0 if ARGV.size > 2

json = JSON.load(File.read ARGV[0])

def find_category(entry)
  return ['aerialway', entry['aerialway']] if entry["aerialway"]
  return ['aeroway', entry['aeroway']] if entry["aeroway"]
  return ['barrier', entry['barrier']] if entry["barrier"]
  return ['boundary', entry['boundary']] if entry["boundary"]
  return ['highway', entry['highway']] if entry["highway"]
  return ['historic', entry['historic']] if entry["historic"]
  return ['information', entry['information']] if entry["information"]
  return ['landuse', entry['landuse']] if entry["landuse"]
  return ['leisure', entry['leisure']] if entry["leisure"]
  return ['man_made', entry['man_made']] if entry["man_made"]
  return ['natural', entry['natural']] if entry["natural"]
  return ['waterway:sign', entry['waterway:sign']] if entry["waterway:sign"]
  return ['power', entry['power']] if entry["power"]
  return ['buoy', entry['buoy']] if entry["buoy"]
  return ['cuisine', entry['cuisine']] if entry["cuisine"]
  return ['office', entry['office']] if entry["office"]
  return ['place', entry['place']] if entry["place"]
  return ['power_source', entry['power_source']] if entry["power_source"]
  return ['public_transport', entry['public_transport']] if entry["public_transport"]
  return ['railway', entry['railway']] if entry["railway"]
  return ['shop', entry['shop']] if entry["shop"]
  return ['sport', entry['sport']] if entry["sport"]
  return ['tourism', entry['tourism']] if entry["tourism"]
  return ['traffic_light', entry['traffic_light']] if entry["traffic_light"]
  return ['traffic_sign', entry['traffic_sign']] if entry["traffic_sign"]
  return ['waterway', entry['waterway']] if entry["waterway"]
  return [nil, 'bridge'] if entry["bridge"]
  return [nil, 'building'] if entry["building"]
  return ['amenity', entry['amenity']] if entry['amenity']
  return [nil, "other"]
end

def email
  imie = %w(ala ola kasia basia tomek atomek xyz)
  name = %w(kowalski nowak)
  domain = %w(gmail.com hotmail.com yahoo.com)
  [imie[rand(imie.size)], name[rand(name.size)], '@', domain[rand(domain.size)]].join("")
end

def review
  "Lorem ipsum #{rand(100)}"
end

idx = 0
categories = Set.new
props = {:street => "Testowa", :house_no => "12A/7", :city => "Nieistniejace", :country => "Poland"}
address = Address.first(props) || Address.create(props)
json.each do |entry|
  idx += 1
  cat, subcat = find_category(entry)
  unless cat.nil?
    dbcat = Category.first(:name => cat) || Category.create(:name => cat)
  end
  dbsubcat = Category.first(:name => subcat) || Category.create(:name => subcat, :parent_id => (dbcat.id rescue nil))
  if (entry["addr:street"] || entry["addr:housenumber"])
    address = Address.create(:street => entry["addr:street"], :house_no => entry["addr:housenumber"], :country => "Poland", :city => entry["addr:city"] )
  end
  place = Place.create(:name => entry["name"], :category_id => dbsubcat.id, :lon => entry["lon"], :lat => entry["lat"], :address_id => address.id) 
  rand(5).times do
    rating = Rating.create(:place_id => place.id, :rating => rand(5) + 1, :email => email, :review => review)
  end
  if ['shop', 'tourism', 'leisure'].include? cat
    Premium.create :place_id => place.id, :provider => place.name, :hour_open => 6 + rand(6), :hour_close => 14 + rand(8)
  end
  Link.create(:place_id => place.id, :url => entry["ft_link"]) if (entry["ft_link"])
  Link.create(:place_id => place.id, :url => "wiki:#{entry["wikipedia"]}") if (entry["wikipedia"])
  print "\r#{idx}" if idx % 1000 == 0
  STDOUT.flush
end
puts ""


