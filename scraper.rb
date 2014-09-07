require 'scraperwiki'
require 'mechanize'

domain = "http://www.onkaparingacity.com"
url = "http://www.onkaparingacity.com/onka/living_here/planning_development/applications_for_public_comment.jsp"

def clean(t)
  if t
    t.squeeze(' ').strip
  end
end

def find_item_from(items, search_key)
  items.each do |item|
    if item =~ search_key
      return item.match(search_key)[1].gsub(/\u00A0 /,' ').gsub('</strong>','').strip
    end
  end
  nil
end

agent = Mechanize.new
page = agent.get(url)


page.search('#body > p').each do |p|

  next if p.previous_element.nil?
  council_reference = p.previous_element.inner_text.split(" ").last

  info = p.inner_html.split("<br>")

  council_reference = find_item_from(info, /Application Number:.* ([^<]+)/)
  address = find_item_from(info, /Subject Land:(.*)/)
  next if address.nil?
  if address.include?('(')
    address = address.split('(').first + address.split(')').last
  end

  # Sometimes there is an empty <p> after a DA
  urls = nil
  urls = p.next_element.next_element.search('a') rescue nil
  urls ||= p.next_element.search('a') rescue nil


  on_notice_from = find_item_from(info, /Advertising Date:(.*)/).split(' ').last.split('/').reverse.join('-') rescue nil

  on_notice_to = find_item_from(info, /Close Date:(.*)/).split(' ').last.split('/').reverse.join('-') rescue nil

  next if council_reference.nil?

  record = {
    'council_reference' => council_reference.strip,
    'address' => clean(address).to_s + ", SA",
    'description' => find_item_from(info, /Nature of Development:(.*)/),
    'info_url' => (domain + urls[0]['href'] rescue nil),
    'comment_url' => (domain + urls[1]['href'] rescue nil),
    'date_scraped' => Date.today.to_s,
    'on_notice_from' => on_notice_from,
    'on_notice_to' => on_notice_to,
  }

  # puts record.to_yaml
  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end