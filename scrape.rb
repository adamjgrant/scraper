#!/usr/bin/env ruby
# You'll need to install these
# gem install json
# gem install httparty

# Maybe we can use Jam here http://www.jamapi.xyz/

require 'httparty'
require 'json'

def get_pages
  baseurl = "http://ohsheglows.com/categories/recipes-2/"
  pages = (2..143).map { |page| "page/#{page}/" }
  pages = [""].concat pages
  urls = pages.map { |page| "#{baseurl}#{page}" }

  links = []

  urls.first(2).each_with_index do |url, index|
    puts "Scraping #{index} of #{urls.count}"
    response = HTTParty.post("http://www.jamapi.xyz/", :body =>
      {
        "url" => url,
        "json_data" => '{"links": [{"elem": ".archive_post_box.hentry a.entry-title", "location": "href"}]}'
      }
    )
    links.concat response['links'].map { |link| link['value'] }.map { |link| link['location'] }
  end

  puts "Found #{links.size} links..."
  get_data_from_links(links)
end

def get_data_from_links(links)
  puts "====="
  puts "Found #{links.count}"
  puts "====="

  recipes = []
  links.first(5).each_with_index do |link, index|
    recipe = {}
    puts "Scraping #{index} of #{links.count}, #{link}"
    response = HTTParty.post("http://www.jamapi.xyz/", :body =>
      {
        "url" => link,

        "json_data" => "{
                            'title': '.headline_area .entry-title',
                            'ingredients': [{'elem': '.post_box .format_text .recipe-content .ingredients.clear .ingredients .ingredient', 'value': 'text' }],
                            'directions': '.post_box .format_text .recipe-content #instructions',
                            'photo': [{'elem': '.post_box .entry-content p img', 'src': 'src' }]
                        }"
      }
    )
    puts response
    recipes.push response unless response.key?("error")
  end

  write_to_database(recipes)
end

def write_to_database(recipes)
  Item.new(
    title: recipe.title,
    provider: "Oh She Glows",
    photo: recipe.photo.first.src.split('/').last,
    category: 1,
    metadata: {
      directions: recipe.directions,
      ingredients: recipe.ingredients
    }
  )
end

get_pages
