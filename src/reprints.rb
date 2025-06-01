require 'net/http'
require 'json'
require 'fileutils'

BASE_URL = 'https://api.scryfall.com/cards/search'
QUERY = "is:old date>=1994-11-16 unique:prints is:nonfoil (in:leb or in:arn or in:atq or in:leg or in:drk or in:fem) include:extras"

def fetch_all_cards(query)
  all_cards = []
  uri = URI(BASE_URL)
  params = { q: query }
  page = 1
  uri.query = URI.encode_www_form(params)

  loop do
    puts "[reprints] Getting page #{page}"
    response = Net::HTTP.get_response(uri)
    break unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    all_cards.concat(data['data'])

    break unless data['has_more']
    page += 1
    sleep 1
    uri = URI(data['next_page']) # Use the next page URL provided by Scryfall
  end

  all_cards
end

cards = fetch_all_cards(QUERY)
puts "[reprints] Found #{cards.length} reprints"

FileUtils.mkdir_p 'cache'

File.open(File.join('cache','reprints.json'), 'w') do |file|
  file.write(JSON.pretty_generate(cards))
end
