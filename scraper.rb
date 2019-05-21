require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

base_url = "http://pathway.onkaparinga.sa.gov.au/ePathway/Production/Web/"

scraper = EpathwayScraper::Scraper.new(
  "http://pathway.onkaparinga.sa.gov.au/ePathway/Production"
)
agent = scraper.agent

# get to the page I can enter DA search
page = agent.get base_url + "GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"

i = 1;
error = 0
cont = true
while cont do
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
  if error == 10
    cont = false
  end
end
