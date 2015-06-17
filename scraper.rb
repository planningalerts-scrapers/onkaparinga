require 'scraperwiki'
require 'mechanize'

use_cache = false
cache_fn = 'cache.html'
domain = 'http://www.onkaparingacity.com'
url = 'http://www.onkaparingacity.com/onka/living_here/planning_development/applications_for_public_comment.jsp'
comment_url = 'mailto:mail@onkaparinga.sa.gov.au?Subject=Planning+application+'

# Clean up repeated and Unicode spaces.
def clean(t)
  t.gsub(/\u00A0|\uC2A0/,' ').squeeze(' ').strip
end

# The structure looks like:
# <strong>Key:</strong>val<br>
#
def maybe_get_field(p, key)
  p.search('strong').each do |elem|
    if elem.inner_text.start_with?(key)
      val = elem.next_sibling
      return clean(val.inner_text) if val.name == 'text'
    end
  end
  return ''
end

def get_field(p, key)
  val = maybe_get_field(p, key)
  raise "Can't find mandator field " + key if val == ''
  return val
end

def maybe_get_date(p, key)
  val = maybe_get_field(p, key)
  return Date.parse(val).to_s if val != ''
  return ''
end

if use_cache and File.exist?(cache_fn)
  body = ''
  File.open(cache_fn, 'r') {|f| body = f.read() }
  page = Nokogiri(body)
else
  agent = Mechanize.new
  page = agent.get(url)
  File.open(cache_fn, 'w') {|f| f.write(page.body) }
end

found = false
page.search('div.centricGeneral p').each do |p|
  next unless p.inner_text =~ /\AApplication Number:/;
  found = true
  council_reference = get_field(p, 'Application Number:')

  # Fix up the address:
  address = get_field(p, 'Subject Land:')
  # "278 (Allot 55 Sec 159 DP 69079) Communication Road, TATACHILLA SA 5171"
  if address.include?('(')
    address = address.split('(').first + address.split(')').last
  end
  address.squeeze!(' ')
  # "Allot 102 Sec 1242 Range Road West, WILLUNGA SOUTH SA 5172"
  address.sub!(/\AAllot \S+ Sec /, '')

  record = {
    'council_reference' => council_reference,
    'address' => address,
    'description' => get_field(p, 'Nature of Development:'),
    'info_url' => url,
    'comment_url' => comment_url + CGI::escape(council_reference),
    'date_scraped' => Date.today.to_s,
    'on_notice_from' => maybe_get_date(p, 'Advertising Date:'),
    'on_notice_to' => maybe_get_date(p, 'Close Date:'),
  }

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts 'Skipping already saved record ' + record['council_reference']
  end
end

raise "No entries found." unless found
