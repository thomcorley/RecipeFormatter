require "./recipe_builder.rb"
require "./current_filenames.rb"

# TODO: Need to select only the recipes which have ingredients, method, serves or makes,
# introduction, and an image. Select the posts which have images in S3 first, then select from that list.
# Can then loop through these recipes and build the .md file for each

# Assumes csv files are called "info.csv", "ingredients.csv", and "method_steps.csv"
# CSV files must be in the same directory as the script is being called from

titles_and_ids = RecipeFormatter.new.get_list_of_titles("info.csv")
current_filenames = CurrentFilenames::LIST

recipe_id = 45

# Convert the array of filenames to an array of hashes
# Keys should be :date and :title
# Match the date with regex and gsub the title to remove dashes and file extension
array_of_dates_and_titles = []
current_filenames.each do |n|
  hash = {}
  date = /20\d{2}-\d{2}-\d{2}/.match(n).to_s
  title = n.sub(date, "").sub("-", "").gsub("-", " ").gsub(".md", "")
  hash[:date] = date
  hash[:title] = title
  array_of_dates_and_titles << hash
end

# Take a recipe title and return the date for that recipe
# Need to downcase the title and sub out the punctuation
# Look this title up in the array_of_dates_and_titles, return the date
def get_date(recipe_title, array)
  title = recipe_title.downcase.gsub(",", "").gsub("\'", "")
  recipe = array.select{|r| r[:title] == title}.first
  recipe[:date]
end

def convert_title_for_url(recipe_title)
  title_for_url = recipe_title.downcase.gsub(",", "").gsub("\'", "").gsub(" ", "_")
  title_for_url
end

# Hash of recipe info
recipe_info = RecipeFormatter.new.get_recipe_info(recipe_id, "info.csv")
# Array of ingredients
ingredients = RecipeFormatter.new.get_ingredients(recipe_id, "ingredients.csv")
# Array of hashes of numbered method steps
method_steps = RecipeFormatter.new.get_method_steps(recipe_id, "method_steps.csv")

# Writing all the recipe information to the file
file = File.open("title.md", "w+") do |file|
  file.puts "---"
  file.puts "layout: post"
  file.puts "date: \"#{get_date(recipe_info[:title], array_of_dates_and_titles)}\""
  file.puts "title: \"#{recipe_info[:title]}\""
  file.puts "author: Tom"
  file.puts "category:"
  file.puts "serves: \"#{recipe_info[:serves]}\""
  # TODO: Add category to info csv, and include it in the SELECTED_PARAMS
  # file.puts "- #{recipe_info[:category]}"
  file.puts "tags:"
  file.puts "-"
  file.puts "---"
  url = "https://s3.eu-west-2.amazonaws.com/grubdaily/#{convert_title_for_url(recipe_info[:title])}.jpg"
  file.puts "<img src=\"#{url}\" />"
  file.puts ""
  file.puts "#{recipe_info[:introduction]}"
  file.puts ""
  file.puts "---"

  ingredients.each{ |i| file.puts "* #{i}" }

  file.puts ""

  method_steps.each do |m|
    file.puts "#{m[:number]}. #{m[:step]}"
    file.puts ""
  end
end
