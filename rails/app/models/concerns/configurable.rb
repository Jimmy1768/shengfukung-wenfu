# frozen_string_literal: true

module Configurable
  extend ActiveSupport::Concern

  class_methods do
    def config_entry(key, default: nil)
      Config::EntryResolver.fetch(key, scope: nil, default: default)
    end
  end

  def config_entry_value(key, default: nil)
    Config::EntryResolver.fetch(key, scope: self, default: default)
  end
end
