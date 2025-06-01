require "vips"
require 'fileutils'
require 'json'

def mask(radius)
  r = radius.ceil
  Vips::Image.new_from_buffer %(
<svg viewBox="0 0 #{IMAGE_WIDTH} #{IMAGE_HEIGHT}">
  <rect rx="#{r}" ry="#{r}" 
    x="0" y="0" width="#{IMAGE_WIDTH}" height="#{IMAGE_HEIGHT}" 
    fill="#fff"/>
</svg>
), ""
end

IMAGE_WIDTH = 745 # pixels
IMAGE_WIDTH_METRIC = 63 # mm
IMAGE_HEIGHT = 1040 # pixels
IMAGE_HEIGHT_METRIC = 88 # mm
PIXELS_PER_MM = IMAGE_HEIGHT / IMAGE_HEIGHT_METRIC

STANDARD_RADIUS_METRIC = 3 # mm
STANDARD_RADIUS = PIXELS_PER_MM * STANDARD_RADIUS_METRIC
STANDARD_MASK = mask(STANDARD_RADIUS)
ALPHA_RADIUS_METRIC = 4 # mm
ALPHA_RADIUS = PIXELS_PER_MM * ALPHA_RADIUS_METRIC
ALPHA_MASK = mask(ALPHA_RADIUS)

ORIGINAL_PATHS = JSON.load_file("config/card_images.json").freeze
ORIGINAL_PATH_COUNT = ORIGINAL_PATHS.length

ORIGINAL_PATHS.each_with_index do |path, i|
  transformed_path = (File.join("cache", "transformed_" + path)).gsub(/jpg$/, 'png')
  if File.exist?(transformed_path)
    puts "[transform] #{i}/#{ORIGINAL_PATH_COUNT} Skipping #{path}, already transformed to #{transformed_path}"
  else
    mask = (path.start_with?("pics/LEA/") ? ALPHA_MASK : STANDARD_MASK)
    puts "[transform] #{i}/#{ORIGINAL_PATH_COUNT} Transforming #{path} to #{transformed_path}"
    im = Vips::Image.new_from_file(path)
    raise "Bad image dimensions #{im.width}x#{im.height}" unless im.width == IMAGE_WIDTH && im.height == IMAGE_HEIGHT 
    im = im.bandjoin(mask[3])
    FileUtils.mkdir_p(File.dirname(transformed_path))
    im.write_to_file(transformed_path)
  end
end

