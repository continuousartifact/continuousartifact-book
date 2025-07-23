require "csv"
require "json"

POPULARITY = {}

# open the CSV file and read its contents into a hash
CSV.foreach("data/mtg-os_card_popularity.csv", headers: true) do |row|
  # extract the card name and popularity score
  card_name = row["card_name"]
  num_decks = row["num_decks"].to_i

  # store the card name and its popularity score in a hash
  POPULARITY[card_name] = num_decks
end

require "sequel"
Sequel::Model.plugin :after_initialize
DB = Sequel.sqlite("data/AllPrintings.sqlite", setup_regexp_function: true)
DB.extension :string_agg
require_relative "card"

CARDS = {}

Card.osm.each do |c|
  CARDS[c.name] = Math.log10(POPULARITY[c.name] || 0)
end

range = CARDS.values.minmax

STARS = CARDS.inject({}) do |memo, (name, score)|
  if score == 0
    memo[name] = 0
  else
    # Normalize the score to a range of 0 to 5 stars
    normalized_score = (score - range.first) / (range.last - range.first)
    memo[name] = (normalized_score * 5).round
  end
  memo
end

File.write("cache/popularity.json", STARS.to_json)