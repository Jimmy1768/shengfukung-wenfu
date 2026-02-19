# frozen_string_literal: true

module Registrations
  class ExistingLookup
    def initialize(scope:, offering:, user_id:, registrant_scope: "self", dependent_id: nil, excluding_id: nil)
      @scope = scope
      @offering = offering
      @user_id = user_id
      @registrant_scope = registrant_scope
      @dependent_id = dependent_id
      @excluding_id = excluding_id
    end

    def find
      return nil if scope.blank? || offering.blank? || user_id.blank?

      query = scope
        .where(user_id:)
        .where(registrable_type: offering.class.name, registrable_id: offering.id)
      if offering.respond_to?(:registration_period_key) && offering.registration_period_key.present?
        query = query.where("metadata ->> 'registration_period_key' = ?", offering.registration_period_key)
      end

      if dependent_selected?
        query = query.where("metadata ->> 'dependent_id' = ?", dependent_id.to_s)
      else
        query = query.where("COALESCE(metadata ->> 'dependent_id', '') = ''")
      end

      query = query.where.not(id: excluding_id) if excluding_id.present?
      query.order(created_at: :desc).first
    end

    private

    attr_reader :scope, :offering, :user_id, :registrant_scope, :dependent_id, :excluding_id

    def dependent_selected?
      registrant_scope.to_s == "dependent" && dependent_id.present?
    end
  end
end
