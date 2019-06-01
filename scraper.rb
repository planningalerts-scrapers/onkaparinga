require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
year = ENV['MORPH_PERIOD'].to_i
puts "Getting data in year `#{year}`, changable via MORPH_PERIOD environment"

EpathwayScraper.scrape_and_save(
  "http://pathway.onkaparinga.sa.gov.au/ePathway/Production",
  list_type: :all_year, year: year
)
