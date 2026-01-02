# frozen_string_literal: true

require "securerandom"

module Util
  # Utility methods for generating slugs and secure tokens.
  module Slugger
    module_function

    # Returns a lowercased slug version of the supplied text.
    def slugify(value, delimiter: "-")
      stripped = value.to_s.downcase.strip
      return "" if stripped.empty?

      slug = stripped.gsub(/[^a-z0-9]+/, delimiter)
      slug.gsub!(/#{Regexp.escape(delimiter)}+/, delimiter)
      slug.gsub!(/^#{Regexp.escape(delimiter)}|#{Regexp.escape(delimiter)}$/, "")
      slug
    end

    # Generates a random token using a URL-safe alphabet.
    # Useful for password reset links, public ids, etc.
    def random_token(length: 48)
      output = +""
      while output.length < length
        output << SecureRandom.urlsafe_base64(length)
        output.delete!("-_")
      end
      output[0, length]
    end
  end
end
