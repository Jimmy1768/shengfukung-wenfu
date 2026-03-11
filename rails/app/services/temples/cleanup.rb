# frozen_string_literal: true

module Temples
  class Cleanup
    Result = Struct.new(
      :registrations,
      :events,
      :services,
      :gatherings,
      keyword_init: true
    )

    def self.call(slug:)
      new(slug:).call
    end

    def initialize(slug:)
      @slug = slug
    end

    def call
      temple = Temple.find_by!(slug: slug)

      Result.new(
        registrations: destroy_scope(temple.temple_registrations.order(:id)),
        events: destroy_scope(temple.temple_events.order(:id)),
        services: destroy_scope(temple.temple_services.order(:id)),
        gatherings: destroy_scope(temple.temple_gatherings.order(:id))
      )
    end

    private

    attr_reader :slug

    def destroy_scope(scope)
      scope.to_a.count do |record|
        record.destroy!
        true
      end
    end
  end
end
