require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "http://pathway.onkaparinga.sa.gov.au/ePathway/Production"
)
agent = scraper.agent

# get to the page I can enter DA search
page = agent.get(scraper.base_url)

i = 1;
error = 0
while error < 10 do
  list = scraper.search_for_one_application(page, "#{i}/#{ENV['MORPH_PERIOD']}")

  count = 0
  scraper.scrape_index_page(list) do |record|
    count += 1
    EpathwayScraper.save(record)
  end
  if count == 0
    error += 1
  else
    error = 0
  end

  # increase i value and scan the next DA
  i += 1
end
