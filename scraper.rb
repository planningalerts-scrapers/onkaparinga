require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "http://pathway.onkaparinga.sa.gov.au/ePathway/Production",
  list_type: :all_this_year, state: "SA"
)
