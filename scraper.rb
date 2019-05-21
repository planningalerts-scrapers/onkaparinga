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

  table = list.search("table.ContentPanel")
  unless ( table.empty? )
    error  = 0

    scraper.extract_table_data_and_urls(table).each do |row|
      data = scraper.extract_index_data(row)
      record = {
        'council_reference' => data[:council_reference],
        'address'           => data[:address],
        'description'       => data[:description],
        'info_url'          => scraper.base_url,
        'date_scraped'      => Date.today.to_s,
        'date_received'     => data[:date_received],
      }

      EpathwayScraper.save(record)
    end
  else
    error += 1
  end

  # increase i value and scan the next DA
  i += 1
  if error == 10
    cont = false
  end
end
