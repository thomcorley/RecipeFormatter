require "csv"
require "active_support/inflector"

class RecipeFormatter
  METRIC_UNITS = ["g", "kg", "mg", "litres", "l", "ml"]
  IRREGULAR_UNITS = ["cloves", "clove", "bulb", "bulbs", "head", "heads", "handfuls", "handful", "glass", "glasses"]
  SELECTED_PARAMS = [:id, :title, :serves, :makes, :introduction, :difficulty]
  TITLE_AND_ID = [:title, :id]

  # Returns an Aray of the formatted ingredients
  def get_ingredients(recipe_id, ingredients_csv_path)
    ingredients_array = []
    final_ingredients_array = []
    irregular_ingredients = []

    CSV.foreach(ingredients_csv_path, headers: true, header_converters: :symbol) do |row|
      ingredients_array << row.to_hash
    end

    ingredients_array.each do |i|
      sentence = String.new

      if i[:quantity] && is_metric?(i[:unit])
        sentence += i[:quantity]
      elsif i[:quantity]
        sentence += i[:quantity] + " "
      end

      # Dealing with units
      if is_irregular?(i[:unit]) && i[:size]
        sentence += i[:size] + " "

        # If it's a single quantity, or a metric unit, singularize the unit
        if i[:quantity].to_i == 1 || is_metric?(i[:unit])
          sentence += i[:unit].singularize + " of "
        # If it's not a single quantity AND not a metric unit, pluralize it
        elsif i[:quantity].to_i > 1 && !is_metric?(i[:unit])
          sentence += i[:unit].pluralize + " of "
        end
      elsif i[:unit] && i[:size]
        sentence += i[:unit] + " of " + i[:size] + " "
      elsif i[:unit]
        sentence += i[:unit] + " of "
      end

      sentence += i[:modifier] + " " if i[:modifier]
      sentence += i[:ingredient] if i[:ingredient]
      sentence += ", " + i[:preparation] if i[:preparation]

      indexed_sentence = [i[:id].to_i, sentence]

      # This is an array of arrays of formatted ingredients
      final_ingredients_array << indexed_sentence
    end

    # Given a recipe ID, find all the ingredients for it.
    recipe_ingredients = final_ingredients_array.select{|i| i[0] == recipe_id.to_i}
    recipe_ingredients = recipe_ingredients.flatten.reject{|i| i == recipe_id.to_i}
    recipe_ingredients.reject{|i| i == recipe_id.to_i}
  end

  # This returns a Hash of recipe information, parameters determined by SELECTED_PARAMS
  def get_recipe_info(recipe_id, info_csv_path)
    recipe_info_array = []

    CSV.foreach(info_csv_path, headers: true, header_converters: :symbol) do |row|
      recipe_info_array << row.to_hash
    end

    recipe_info_hash = recipe_info_array.select{|i| i[:id] == recipe_id}.first

    # Select only the parameters we're concerned with for now.
    # This will be :id, :title, :serves,, :makes, :introduction, :difficulty,
    # Returns a Hash of the selected params
    selected_info = recipe_info_hash.keep_if{|k, v| SELECTED_PARAMS.include?(k)}
    selected_info
  end

  # Returns an array of hashes of all the recipe info
  def get_all_recipes_info(info_csv_path)
    recipe_info_array []

    CSV.foreach(info_csv_path, headers: true, header_converters: :symbol) do |row|
      recipe_info_array << row.to_hash
    end
    recipe_info_array
  end

  # Returns an array of hashes of the title and id of each recipe
  def get_list_of_titles(info_csv_path)
    recipe_info_array = []

    CSV.foreach(info_csv_path, headers: true, header_converters: :symbol) do |row|
      recipe_info_array << row.to_hash
    end

    titles_and_ids = []
    recipe_info_array.each do |hash|
      hash = hash.select{|k, v| TITLE_AND_ID.include?(k)}
      titles_and_ids << hash
    end
    titles_and_ids
  end

  # Returns an array of hashes of the numbered method steps, with keys :number and :step
  def get_method_steps(recipe_id, method_steps_csv)
    method_steps_array = []
    numbered_steps_array = Array.new

    CSV.foreach(method_steps_csv, headers: true, header_converters: :symbol) do |row|
      method_steps_array << row.to_hash
    end

    recipe_steps = method_steps_array.select{|step| step[:id].to_i == recipe_id}

    counter = 1

    recipe_steps.each do |step|
      hash = {}
      hash[:number] = counter.to_s
      hash[:step] = step[:step]
      numbered_steps_array << hash
      counter += 1
    end
    numbered_steps_array
  end

  def is_metric?(unit)
    METRIC_UNITS.include?(unit)
  end

  def is_irregular?(unit)
    IRREGULAR_UNITS.include?(unit)
  end
end
