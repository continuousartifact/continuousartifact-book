require 'json'

task default: :open

# Check that all files are present
task :check do
  missing = []
  JSON.load_file("config/card_images.json").concat(["data/AllPrintings.sqlite", "data/AllPrices.json"]).freeze.each do |f|
    unless File.exist?(f)
      missing << f
    end
  end
  if missing.empty?
    puts "[check] All files are present."
  else
    puts "[check] Missing files:"
    missing.each { |f| puts "[check] - #{f}" }
    exit 1
  end
end

# Normalize filenames to match the expected format
task :normalize do
  NORMALIZATIONS = {
    "pics/3ED/El-Hajjaj.xlhq.jpg" => "pics/3ED/El-Hajjâj.xlhq.jpg",
    "pics/ARN/Dandan.xlhq.jpg" => "pics/ARN/Dandân.xlhq.jpg",
    "pics/ARN/El-Hajjaj.xlhq.jpg" => "pics/ARN/El-Hajjâj.xlhq.jpg",
    "pics/ARN/Ghazban Ogre.xlhq.jpg" => "pics/ARN/Ghazbán Ogre.xlhq.jpg",
    "pics/ARN/Ifh-Biff Efreet.xlhq.jpg" => "pics/ARN/Ifh-Bíff Efreet.xlhq.jpg",
    "pics/ARN/Junun Efreet.xlhq.jpg" => "pics/ARN/Junún Efreet.xlhq.jpg",
    "pics/ARN/Juzam Djinn.xlhq.jpg" => "pics/ARN/Juzám Djinn.xlhq.jpg",
    "pics/ARN/Khabal Ghoul.xlhq.jpg" => "pics/ARN/Khabál Ghoul.xlhq.jpg",
    "pics/ARN/Ring of Ma'ruf.xlhq.jpg" => "pics/ARN/Ring of Ma'rûf.xlhq.jpg",
    "pics/LEG/rathi Berserker.xlhq.jpg" => "pics/LEG/Aerathi Berserker.xlhq.jpg",
  }
  NORMALIZATIONS.each do |old, new|
    if File.exist?(new)
      puts "[normalize] File #{new} already exists, skipping normalization."
    elsif File.exist?(old)
      FileUtils.cp(old, new)
      puts "[normalize] Copied #{old} to #{new}"
    else
      puts "[normalize] File #{old} does not exist, skipping."
    end
  end
end

# Generate the pricing cache
task :pricing do
  FileUtils.mkdir_p("cache")
  sh <<~SH
    jq '.data | with_entries(.value |= .paper) | del(..|nulls) | with_entries(.value |= [(.cardkingdom.retail.normal // {})[], (.cardsphere.retail.normal // {})[], (.tcgplayer.retail.normal // {})[], (.cardmarket.retail.normal // {})[]]) | select(length > 0)' data/AllPrices.json > cache/prices_per_card.json
  SH
  puts "[pricing] Pricing cache generated."
end

# Generate the reprint cache
task :reprints do
  ruby "src/reprints.rb"
  puts "[reprints] Reprint cache generated."
end

# Transform the images
task :transform do
  ruby "src/transform.rb"
  puts "[transform] Images transformed."
end

# Generate the sets cache
task :sets do
  ruby "src/sets.rb"
  puts "[sets] Sets cache generated."
end

# Runs setup tasks
task setup: [:normalize, :check, :transform, :pricing, :sets, :reprints] do
  puts "[setup] Setup complete."
end

# Produce book.html
task :build do
  ruby "src/build.rb"
  puts "[build] Book HTML generated."
end

# Use weasyprint to produce book.pdf from book.html
task render: :build do
  sh "weasyprint build/book.html build/book.pdf"
  puts "[render] Book PDF generated."
end

# Use pdfnup to produce book-imposed.pdf from book.pdf
task impose: :render do
  sh "pdfjam --nup 2x1 --landscape --papersize 13in,19in --outfile build/book-imposed.pdf build/book.pdf '{},1-'"
  puts "[impose] Book imposed PDF generated."
end

# Open book-imposed.pdf
task open: :impose do
  puts "[open] Opening build/book-imposed.pdf . . ."
  sh "open build/book-imposed.pdf"
end