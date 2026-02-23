# frozen_string_literal: true

module Account
  class ContactTempleRequestForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :subject, :string
    attribute :message, :string
    attribute :website, :string # honeypot

    validates :subject, presence: true, length: { maximum: 120 }
    validates :message, presence: true, length: { minimum: 10, maximum: 2_000 }
    validate :honeypot_blank

    def initialize(params: nil)
      super(params.presence || {})
      normalize!
    end

    private

    def normalize!
      self.subject = sanitize_line(subject)
      self.message = sanitize_body(message)
      self.website = website.to_s.strip
    end

    def sanitize_line(value)
      stripped = ActionController::Base.helpers.strip_tags(value.to_s)
      stripped.squish.presence
    end

    def sanitize_body(value)
      stripped = ActionController::Base.helpers.strip_tags(value.to_s)
      stripped.gsub(/\r\n?/, "\n").strip.presence
    end

    def honeypot_blank
      return if website.blank?

      errors.add(:base, "Invalid submission")
    end
  end
end
