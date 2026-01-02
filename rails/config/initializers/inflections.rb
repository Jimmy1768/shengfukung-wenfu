# config/initializers/inflections.rb
#
# Customize English inflection rules for your app.
# Rails uses inflections to determine:
# - model and controller class names
# - table names
# - route naming
# - singular/plural conversions
#
# Most apps do NOT need custom rules.
# This file exists so you can add rules later when the domain vocabulary grows.

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "OAuth"

  # Examples:
  #
  # inflect.acronym "API"
  # inflect.acronym "SMS"
  #
  # inflect.uncountable %w[ equipment data news ]
  #
  # inflect.irregular "medium", "media"
  # inflect.irregular "curriculum", "curricula"
end
