# frozen_string_literal: true

module Account
  class DependentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :english_name, :string
    attribute :native_name, :string
    attribute :relationship_label, :string
    attribute :birthdate, :date
    attribute :phone, :string
    attribute :email, :string
    attribute :notes, :string

    validates :english_name, presence: true

    attr_reader :user, :link

    def initialize(user:, link: nil, params: nil)
      @user = user
      @link = link
      attributes = params.presence || extracted_attributes
      super(attributes)
    end

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        dependent = link&.dependent || Dependent.new
        dependent.assign_attributes(
          english_name:,
          native_name:,
          relationship_label: relationship_label.presence || dependent.relationship_label,
          birthdate:
        )
        dependent.metadata = (dependent.metadata || {}).merge(metadata_payload)
        dependent.save!

        user_link = link || user.user_dependents.find_or_initialize_by(dependent:)
        user_link.role ||= "family"
        user_link.relationship_label = relationship_label.presence || user_link.relationship_label
        user_link.metadata = (user_link.metadata || {}).merge(metadata_payload)
        user_link.save!
        @link = user_link
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def extracted_attributes
      dependent = link&.dependent
      metadata = dependent&.metadata || {}
      {
        english_name: dependent&.english_name,
        native_name: dependent&.native_name,
        relationship_label: link&.relationship_label || dependent&.relationship_label,
        birthdate: dependent&.birthdate,
        phone: metadata["phone"],
        email: metadata["email"],
        notes: metadata["notes"]
      }
    end

    def metadata_payload
      {
        "phone" => phone,
        "email" => email,
        "notes" => notes
      }.compact
    end
  end
end
