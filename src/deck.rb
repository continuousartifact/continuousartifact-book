class DeckCard
  attr_reader :card, :qty

  def initialize(card, qty)
    @card = card
    @qty = qty
  end
end

class Deck
  class << self
    def from_csv(csv, library:, color:)
      cards_by_type = Card::TYPES.keys.inject({}) do |h, t|
        h[t] = csv.select { |r| r["type"] == t.to_s }.map do |r|
          card = library.find { |c| c.id == r["card"].downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '') } or raise "Card not found: #{r["card"]}"
          DeckCard.new(card, r["qty"].to_i)
        end
        h
      end
      new(cards_by_type, color: color)
    end
  end

  COLUMNS = 5

  def initialize(cards_by_type, color:)
    @cards_by_type = cards_by_type
    @color = color
  end

  def get_cards_by_type(t)
    Card::TYPES[t] or raise "Unknown type: #{t}"
    @cards_by_type[t]
  end

  def cards
    @cards_by_type.values.flatten
  end

  def card_columns
    debug "Columns: #{COLUMNS}"
    debug "Total slots: #{slots}"
    debug "Slots per column: #{slots_per_column}"
    columns = Array.new(COLUMNS) { [] }
    i = 0
    debug columns.inspect
    cards.each do |c|
      debug c.inspect
      slots_in_current_column = columns[i].inject(0) { |sum, c| sum + (c.card.basic_land? ? 1 : c.qty) + 6 }
      debug "slots in current column #{i}: #{slots_in_current_column}"
      debug "slots needed for current card: #{(c.card.basic_land? ? 1 : c.qty) + 6}"
      if i + 1 == COLUMNS
        debug "Last column, no need to check for overflow"
      elsif slots_in_current_column + (c.card.basic_land? ? 1 : c.qty) + 6 > slots_per_column + 2
        debug "Moving to next column"
        i += 1
      end
      debug "Adding card to column #{i}"
      columns[i] << c
    end
    columns
  end

  private

  def slots
    @slots ||= cards.inject(0) do |sum, c|
      debug "Adding #{c.card.name} [#{c.card.basic_land?}] (#{c.qty}) to slots"
      debug "Current sum: #{sum}"
      debug "Adding #{(c.card.basic_land? ? 1 : c.qty) + 6} to sum"
      sum += (c.card.basic_land? ? 1 : c.qty) + 6
      debug "New sum: #{sum}"
      sum
    end
  end

  def slots_per_column
    30
    # @slots_per_column ||= (slots / (COLUMNS)).ceil
  end

  def debug(message)
    puts "[build] [DEBUG] #{message}" if ENV['DEBUG']
  end
end