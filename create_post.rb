require "./recipe_formatter.rb"
require "./current_filenames.rb"
require "./recipes_with_images"

CONNECTIVES = ["and", "with", "a", "la", "of", "for", "au", "the", "le"]

# TODO: Need to select only the recipes which have ingredients, method, serves or makes,
# introduction, and an image. Select the posts which have images in S3 first, then select from that list.
# Can then loop through these recipes and build the .md file for each
formatter = RecipeFormatter.new
info_path = "csv/info.csv"
ingredients_path = "csv/ingredients.csv"
method_steps_path = "csv/method_steps.csv"

# Get a list of info for all the recipes
# Select only the ones that have :introduction, :serves/:makes, ingredients and method_steps
ids_of_recipes_with_images = RecipesWithImages::LIST
ids_of_complete_recipes = []

ids_of_recipes_with_images.each do |id|
  info = formatter.get_recipe_info(id, info_path)
  ingredients = formatter.get_ingredients(id, ingredients_path)
  method_steps = formatter.get_method_steps(id.to_i, method_steps_path)

  if method_steps.first[:step] &&
    ingredients.reject{|i| i.is_a?(Integer)}.first != "" &&
    info[:serves] || info[:makes] &&
    info[:introduction]

    ids_of_complete_recipes << id
  end
end

# Assumes csv files are called "info.csv", "ingredients.csv", and "method_steps.csv"
# CSV files must be in the same directory as the script is being called from

titles_and_ids = formatter.get_list_of_titles(info_path)
current_filenames = CurrentFilenames::LIST

# Convert the array of currently existing filenames to an array of hashes
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

def generate_path_from_title(snake_case_title)
  title_array = snake_case_title.split("_")
  stripped_title = title_array.reject{|i| CONNECTIVES.include?(i)}
  stripped_title.join("_").prepend("/")
end

recipe_count = 0

ids_of_complete_recipes.each do |id|

  info = formatter.get_recipe_info(id, info_path)
  ingredients = formatter.get_ingredients(id, ingredients_path)
  method_steps = formatter.get_method_steps(id.to_i, method_steps_path)
  date = get_date(info[:title], array_of_dates_and_titles)
  snake_case_title = convert_title_for_url(info[:title])
  path = generate_path_from_title(snake_case_title)
  image_url = "https://s3.eu-west-2.amazonaws.com/grubdaily/#{snake_case_title}.jpg"
  array_of_tags = info[:tags].split

  info[:serves] ? recipe_yeild = info[:serves] : recipe_yeild = info[:makes]

  # Writing all the recipe information to the file
  file = File.open("#{date}-#{snake_case_title}.md", "w+") do |file|
    file.puts "---"
    file.puts "layout: post"
    file.puts "date: \"#{date}\""
    file.puts "title: \"#{info[:title]}\""
    file.puts "permalink: \"#{path}\""
    file.puts "author: Tom"
    file.puts "category: \"#{info[:category]}\""
    file.puts "serves: \"#{info[:serves]}\""
    file.puts "makes: \"#{info[:makes]}\""
    file.puts "tags:"
    array_of_tags.each{ |tag| file.puts "- #{tag}" }
    file.puts "img_url: \"#{image_url}\""
    file.puts "recipe:"
    file.puts " \"@context\": http://schema.org/"
    file.puts " \"@type\": Recipe"
    file.puts " name: #{info[:title]}"
    file.puts " author: Tom"
    file.puts " image: #{image_url}"
    file.puts " datePublished: #{date}"
    file.puts " totalTime:"
    file.puts " recipeYield: #{recipe_yeild}"
    file.puts " description:"
    file.puts " aggregateRating:"
    file.puts "   ratingValue: 4.5"
    file.puts "   reviewCount: 12"
    file.puts " recipeIngredient:"
    ingredients.each{ |i| file.puts "  - \"#{i}\"" }
    file.puts " recipeInstructions:"
    method_steps.each do |m|
      file.puts "   - \"#{m[:step]}\""
    end
    file.puts "---"
    file.puts "<img src=\"#{image_url}\" alt=\"#{info[:title]}\" />"
    file.puts ""
    file.puts "#{info[:introduction]}"
    file.puts ""
    file.puts "---"

    ingredients.each{ |i| file.puts "* #{i}" }

    file.puts ""

    method_steps.each do |m|
      file.puts "#{m[:number]}. #{m[:step]}"
      file.puts ""
    end
    puts "#{info[:title]}.......done"
  end
  recipe_count += 1
end

puts "Successfully exported #{recipe_count} recipes"
