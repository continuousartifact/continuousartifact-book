require "sequel"
require 'tilt'
require 'tilt/erb'
require 'json'
require 'set'
require 'csv'
require 'pry'
require 'fileutils'
Sequel::Model.plugin :after_initialize
DB = Sequel.sqlite("data/AllPrintings.sqlite", setup_regexp_function: true)
DB.extension :string_agg
require_relative "card"
require_relative "deck"
$REPRINT_SETS = Set.new
REPRINT_SET_CACHE_PATH = File.join("cache", "reprint_sets.json")
CACHED_REPRINT_SETS = File.exist?(REPRINT_SET_CACHE_PATH) ? JSON.load_file(REPRINT_SET_CACHE_PATH).freeze : {}.freeze
DECKS = CSV.read(File.join("config", "decks.csv"), headers: true).freeze
SET_METADATA = JSON.load_file(File.join("cache", "sets.json")).freeze

CARDS = {}
Card::COLORS.each do |k,v|
  CARDS[k] = []
  if k == :Z
    basis = Card.osm.exclude(colors: Card::COLOR_CODES) #.limit(9)
  elsif k == :A
    basis = Card.osm.where(type: /Artifact/)
  elsif k == :L
    basis = Card.osm.where(type: /Land/)
  else
    basis = Card.osm.where(colors: k.to_s) #.limit(9)
  end
  basis.select_group(:name)
    .select_append{min(printings).as(printings)}
    .select_append{avg(edhrecRank).as(edhrecRank)}
    .select_append{string_agg(rarity, ",").as(rarities)}
    .select_append{string_agg(uuid, ",").as(uuids)}
    .select_append{string_agg(artist, "!").as(artists)}
    .order(:name).each do |c|
      CARDS[k] << c
  end
end

# we have to swap Dark Ritual with Darkness in order to make room for the note 🫣
dark_ritual_index = CARDS[:B].index { |c| c.name == "Dark Ritual" }
dark_ritual = CARDS[:B].delete_at(dark_ritual_index)
CARDS[:B].insert(dark_ritual_index + 1, dark_ritual)

# same with Birds 🫣
birds_index = CARDS[:G].index { |c| c.name == "Birds of Paradise" }
birds = CARDS[:G].delete_at(birds_index)
CARDS[:G].insert(birds_index - 1, birds)

# same with Marsh Viper 🫣
marsh_index = CARDS[:G].index { |c| c.name == "Marsh Viper" }
marsh = CARDS[:G].delete_at(marsh_index)
CARDS[:G].insert(marsh_index + 1, marsh)

# same with Millstone 🫣
millstone_index = CARDS[:A].index { |c| c.name == "Millstone" }
millstone = CARDS[:A].delete_at(millstone_index)
CARDS[:A].insert(millstone_index - 1, millstone)

# same with The Tabernacle at Pendrell Vale 🫣
tabernacle_index = CARDS[:L].index { |c| c.name == "The Tabernacle at Pendrell Vale" }
tabernacle = CARDS[:L].delete_at(tabernacle_index)
CARDS[:L].insert(tabernacle_index - 1, tabernacle)

# ok enough of that
CARDS.freeze
LIBRARY = CARDS.values.flatten.freeze
CARD_COUNT = CARDS.values.map(&:size).sum
template = Tilt.new('templates/book.html.erb')
FileUtils.mkdir_p("build")
File.open(File.join("build","book.html"), "w") do |f|
  f.write(template.render(Object.new, cards: CARDS, reprint_sets: CACHED_REPRINT_SETS, decks: DECKS, card_count: CARD_COUNT.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse, library: LIBRARY))
end

# Reprint housekeeping
rs = $REPRINT_SETS.inject({}) do |h, s|
  x = SET_METADATA.find { |set| set["code"] == s }
  h[s] = {
    name: x["name"],
    released_at: x["released_at"],
    set_type: x["set_type"]
  }
  h
end
puts "[build] Found #{rs.keys.length} reprint sets while building the book, writing to cache"
unless File.exist?(REPRINT_SET_CACHE_PATH)
  puts "[build] WARNING: because you're building this for the first time, you'll likely have to re-run the build to pick up the reprints"
end
rs = rs.sort_by { |k,v| Date.parse(v[:released_at]) }.to_h
File.open(REPRINT_SET_CACHE_PATH, "w") do |f|
  f.write(JSON.pretty_generate(rs))
end

# Report and exit
puts "[build] Done building with #{CARDS.values.map(&:size).sum} cards"