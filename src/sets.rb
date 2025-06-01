require 'net/http'
require 'json'
require 'uri'

def fetch_sets
  sets = []
  url = 'https://api.scryfall.com/sets'
  
  loop do
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    
    sets.concat(data['data'].map { |set| { name: set['name'], code: set['code'], released_at: set['released_at'], set_type: set['set_type'] } })
    
    break unless data['has_more']
    sleep 1
    url = data['next_page']
  end
  
  sets
end

def write_sets_to_file
  sets = fetch_sets
  File.open(File.join('cache', 'sets.json'), 'w') do |file|
    file.write(JSON.pretty_generate(sets))
  end
end

write_sets_to_file
