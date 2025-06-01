require 'fileutils'

class Card < Sequel::Model

  OSM_SETS = ["LEA","LEB","2ED","ARN","ATQ","3ED","LEG","DRK","FEM"].freeze
  REPRINTS = JSON.load_file(File.join("cache", "reprints.json")).freeze
  COLORS = {
    W: "White",
    U: "Blue",
    B: "Black",
    R: "Red",
    G: "Green",
    Z: "Multicolor",
    A: "Artifact",
    L: "Land",
  }.freeze
  COLOR_CODES = COLORS.keys.map(&:to_s).push('').freeze
  DECKED = %i(W U B R G).freeze
  INTROD = %i(Z A L).freeze
  TYPES = {
    C: "Creature",
    S: "Spell",
    A: "Artifact",
    E: "Enchantment",
    L: "Land",
  }.freeze
  FILENAME_SUFFIXES = %w(1 2 3 4) + ['']
  dataset_module do
    def osm
      filter(setCode: OSM_SETS).or(name: PROMO_CARDS)
    end
  end
  PRICES = JSON.load_file("cache/prices_per_card.json").freeze
  SET_SHORTHAND = {
    'LEA' => 'A',
    'LEB' => 'B',
    '2ED' => '2',
    'ARN' => 'N',
    'ATQ' => 'Q',
    '3ED' => '3',
    'LEG' => 'L',
    'DRK' => 'D',
    'FEM' => 'F',
    'CED' => 'C',
    'CEI' => 'I',
    'promos' => 'P',
  }.freeze

  BASIC_LANDS = %w(Plains Island Swamp Mountain Forest).freeze
  PROMO_CARDS = ['Arena', 'Sewers of Estark', 'Nalathni Dragon'].freeze

  RARITIES = %w(C U R)

  attr_reader :picture_set, :picture_path

  def after_initialize
    super
    @picture_set, @picture_path = transformed_picture_set_and_path
  end

  def safe_name
    self[:name].gsub(':','')
  end

  def id
    @id ||= safe_name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def sets
    promo? ? ['promos'] : OSM_SETS.intersection(self[:printings].split(", "))
  end

  def rank
    return unless self[:edhrecRank]
    self[:edhrecRank].to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def rarity
    RARITIES.intersection(self[:rarities].split(",").uniq.map do |r|
      r[0].upcase
    end).join('/')
  end

  def uuids
    self[:uuids].split(",")
  end

  def artists
    self[:artists].split("!").uniq
  end

  def price_range
    p = prices.compact
    return unless p.any?
    min, max = p.minmax.map(&:round)
    if min == max
      min.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    else
      "#{min.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}–#{max.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    end
  end

  def reprint_sets
    @reprint_sets ||= begin
      return [] if basic_land?
      r = REPRINTS.select { |r| r['name'] == self[:name] && artists.include?(r['artist']) && !r['oversized'] && r['set'] != "ice" }.sort_by { |r| Date.parse(r['released_at']) }.map { |r| r['set'] }.uniq
      $REPRINT_SETS.merge(r)
      r
    end
  end

  def has_reprint?
    reprint_sets.any?
  end

  def basic_land?
    BASIC_LANDS.include?(self[:name])
  end

  def promo?
    PROMO_CARDS.include?(self[:name])
  end

  def noted?
    @noted ||= File.exist? note_path
  end

  def note_path
    @note_path ||= File.join("copy", "notes", "#{id}.md")
  end

  private

  def sets_with_pictures
    promo? ? ['promos'] : sets.intersection(OSM_SETS)
  end

  def prices
    uuids.map do |uuid|
      PRICES[uuid]
    end.flatten
  end

  def transformed_picture_set_and_path
    set, path = picture_set_and_path
    transformed_path = (File.join("cache", "transformed_" + path)).gsub(/jpg$/, 'png')
    unless File.exist?(transformed_path)
      raise "Transformed image missing: #{transformed_path}"
    end
    [set, transformed_path]
  end

  def picture_set_and_path
    sets_with_pictures.inject([]) do |x, set|
      picture_filenames(set).each do |fn|
        filename = "pics/#{set}/#{fn}.xlhq.jpg"
        x << [set, filename] if File.exist?(filename)
      end
      x
    end.sample
  end

  def picture_filenames(set)
    FILENAME_SUFFIXES.map do |suffix|
      "#{safe_name}#{suffix}"
    end
  end
end