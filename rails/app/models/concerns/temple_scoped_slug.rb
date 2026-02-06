# frozen_string_literal: true

module TempleScopedSlug
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_slug
    before_validation :assign_generated_slug, if: -> { slug.blank? }
  end

  private

  def normalize_slug
    return if slug.blank?

    self.slug = slug.to_s.parameterize
  end

  def assign_generated_slug
    base = title.to_s.parameterize.presence || SecureRandom.hex(4)
    self.slug = unique_slug_for(base)
  end

  def unique_slug_for(base)
    candidate = base
    counter = 2
    while slug_taken?(candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    candidate
  end

  def slug_taken?(candidate)
    return false if temple_id.blank?

    scope = self.class.where(temple_id:)
    scope = scope.where.not(id:) if persisted?
    scope.exists?(slug: candidate)
  end
end
