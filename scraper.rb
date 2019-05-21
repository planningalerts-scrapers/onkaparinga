require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s

puts "Getting data in year `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

base_url = "http://pathway.onkaparinga.sa.gov.au/ePathway/Production/Web/"

agent = Mechanize.new

# get to the page I can enter DA search
page = agent.get base_url + "GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"

# local DB lookup if DB exist and find out what is the maxDA number
i = 1;
sql = "select * from data where `council_reference` like '%/#{ENV['MORPH_PERIOD']}'"
results = ScraperWiki.sqliteexecute(sql) rescue false
if ( results )
  results.each do |result|
    maxDA = result['council_reference'].gsub!("/#{ENV['MORPH_PERIOD']}", '')
    if maxDA.to_i > i
      i = maxDA.to_i
    end
  end
end

error = 0
cont = true
while cont do
  form = page.form
  form.field_with(:name=>'ctl00$MainBodyContent$mGeneralEnquirySearchControl$mTabControl$ctl04$mFormattedNumberTextBox').value = i.to_s + '/' + ENV['MORPH_PERIOD']
  button = form.button_with(:value => "Search")
  list = form.click_button(button)

  table = list.search("table.ContentPanel")
  unless ( table.empty? )
    error  = 0
    tr     = table.search("tr.ContentPanel")

    record = {
      'council_reference' => tr.search('a').inner_text,
      'address'           => tr.search('span')[3].inner_text,
      'description'       => tr.search('span')[2].inner_text.gsub("\n", '. ').squeeze(' '),
      'info_url'          => base_url + 'GeneralEnquiry/' + tr.search('a')[0]['href'],
      'date_scraped'      => Date.today.to_s,
      'date_received'     => Date.parse(tr.search('span')[1].inner_text).to_s,
    }

    puts "Saving record " + record['council_reference'] + ", " + record['address']
#      puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    error += 1
  end

  # increase i value and scan the next DA
  i += 1
  if error == 10
    cont = false
  end
end
