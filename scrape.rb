#!/usr/bin/env ruby
# You'll need to install these
# gem install nokogiri
# gem install csv
# gem install find
# gem install sanitize
# gem install json
# gem install httparty

require 'find'
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'csv'

# Maybe we can use Jam here http://www.jamapi.xyz/

require 'httparty'
require 'json'

def scrape
  baseurl = "http://ohsheglows.com/categories/recipes-2/"
  pages = (2..143).map { |page| "page/#{page}/" }
  pages = [""].concat pages
  urls = pages.map { |page| "#{baseurl}#{page}" }

  links = []

  urls.each_with_index do |url, index|
    puts "Scraping #{index} of #{urls.count}"
    response = HTTParty.post("http://www.jamapi.xyz/", :body => 
      {
        "url" => url,
        "json_data" => '{"links": [{"elem": ".archive_post_box.hentry a.entry-title", "location": "href"}]}'
      }
    )
    links.concat response['links'].map { |link| link['value'] }.map { |link| link['location'] }
  end

  puts "====="
  puts "Found #{links.count}"
  puts "====="

  recipes = []
  links.each_with_index do |link, index|
    recipe = {}
    puts "Scraping #{index} of #{links.count}, #{link}"
    response = HTTParty.post("http://www.jamapi.xyz/", :body => 
      {
        "url" => link,

        "json_data" => "{
                            'ingredients': [{'elem': '.post_box .format_text .recipe-content .ingredients.clear .ingredients .ingredient', 'value': 'text' }],
                            'directions': '.post_box .format_text .recipe-content #instructions'
                        }"
        # "json_data" => "{
        #                   'ingredients': '.post_box .format_text .recipe-content .ingredients.clear .ingredients',
        #                   'directions': '.post_box .format_text .recipe-content .ingredients.clear #instructions'
        #                 }"
      }
    )
    puts response
    recipes.push response unless response.key?("error")
  end

  puts recipes.to_json
end

scrape
