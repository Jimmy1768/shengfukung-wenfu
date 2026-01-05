# frozen_string_literal: true

module Account
  class ProfileForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :english_name, :string
    attribute :native_name, :string
    attribute :phone, :string
    attribute :city, :string
    attribute :notes, :string

    validates :english_name, presence: true

    attr_reader :user

    def initialize(user:, params: nil)
      @user = user
      attributes = params.presence || extracted_attributes(user)
      super(attributes)
    end

    def save
      return false unless valid?

      user.assign_attributes(
        english_name:,
        native_name:,
        metadata: (user.metadata || {}).merge(profile_metadata)
      )
      user.save!
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def extracted_attributes(record)
      metadata = record.metadata || {}
      {
        english_name: record.english_name,
        native_name: record.native_name,
        phone: metadata["phone"],
        city: metadata["city"],
        notes: metadata["notes"]
      }
    end

    def profile_metadata
      {
        "phone" => phone,
        "city" => city,
        "notes" => notes
      }.compact
    end
  end
end
