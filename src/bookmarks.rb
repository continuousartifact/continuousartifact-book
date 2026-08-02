require "shellwords"
require "tempfile"

# weasyprint builds a PDF outline for book.pdf from the bookmark-* properties in
# matter.css, but pdfjam throws it away when it imposes the spreads. Copy the
# outline over to book-imposed.pdf, remapping the page numbers as we go.
#
# The imposition is `--nup 2x1 ... '{},1-'`: one blank page, then every page of
# book.pdf, two per sheet. So book page 1 sits alone on imposed sheet 1, pages 2
# and 3 share sheet 2, pages 4 and 5 share sheet 3, and so on.

SOURCE  = File.join("build", "book.pdf")
IMPOSED = File.join("build", "book-imposed.pdf")

[SOURCE, IMPOSED].each do |f|
  raise "Missing #{f} — run `rake impose` first" unless File.exist?(f)
end

# cpdf prints a licence banner on some runs, so match strictly and ignore the rest.
# Format: LEVEL "TITLE" PAGE [open] ["DESTINATION"]
ENTRY = /\A(\d+) "((?:[^"\\]|\\.)*)" (\d+)( open)?/

listing = `cpdf -list-bookmarks #{Shellwords.escape(SOURCE)}`
raise "cpdf could not read bookmarks from #{SOURCE}" unless $?.success?

entries = listing.lines.filter_map do |line|
  next unless (m = ENTRY.match(line.strip))
  { level: m[1].to_i, title: m[2], page: m[3].to_i, open: m[4] }
end

if entries.empty?
  raise "No bookmarks in #{SOURCE}. The bookmark-level rules in build/style/matter.css " \
        "are what generate them — check they still match the document."
end

def imposed_page(n)
  n / 2 + 1
end

Tempfile.create(["bookmarks", ".txt"]) do |f|
  entries.each do |e|
    f.puts "#{e[:level]} \"#{e[:title]}\" #{imposed_page(e[:page])}#{e[:open]}"
  end
  f.flush

  output = "#{IMPOSED}.tmp"
  system("cpdf", "-add-bookmarks", f.path, IMPOSED, "-o", output, exception: true)
  File.rename(output, IMPOSED)
end

top = entries.count { |e| e[:level].zero? }
puts "[bookmarks] Added #{entries.size} bookmarks (#{top} top-level) to #{IMPOSED}"
