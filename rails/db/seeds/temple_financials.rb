# frozen_string_literal: true

require "securerandom"

module Seeds
  module TempleFinancials
    extend self

    OFFERINGS = {
      "shenfukung-wenfu" => [
        {
          slug: "lantern-lighting",
          offering_type: TempleOffering::OFFERING_TYPES[:lamp],
          title: "祈福點燈",
          description: "每盞供燈代表一家平安，含安太歲與祈福卡片。",
          price_cents: 3000,
          currency: "TWD",
          period: "春季祈福",
          starts_on: Date.new(2026, 1, 1),
          ends_on: Date.new(2026, 3, 31),
          available_slots: 120,
          registrations: [
            {
              user_email: Seeds::AuthCore::PRIMARY_EMAIL,
              quantity: 2,
              payment_method: TemplePayment::PAYMENT_METHODS[:cash],
              payment_reference: "PMT-SHF-001",
              contact_name: "Chen Wen-te",
              contact_phone: "0912-345-678"
            }
          ]
        },
        {
          slug: "pudu-table",
          offering_type: TempleOffering::OFFERING_TYPES[:table],
          title: "普渡供桌",
          description: "含水果、鮮花與供品，可於指定檔期代為佈置。",
          price_cents: 5000,
          currency: "TWD",
          period: "中元普渡",
          starts_on: Date.new(2026, 7, 1),
          ends_on: Date.new(2026, 8, 15),
          registrations: [
            {
              user_email: Seeds::AuthCore::SECONDARY_EMAIL,
              quantity: 1,
              payment_method: TemplePayment::PAYMENT_METHODS[:cash],
              payment_reference: "PMT-SHF-002",
              contact_name: "Lin Hsin-yu",
              contact_phone: "0987-654-321"
            }
          ]
        }
      ],
      "demo-lotus" => [
        {
          slug: "meditation-retreat",
          offering_type: TempleOffering::OFFERING_TYPES[:ritual],
          title: "蓮心靜觀禪修",
          description: "三日禪修課程，含手作香氛、音樂療癒。",
          price_cents: 4200,
          currency: "TWD",
          starts_on: Date.new(2026, 4, 12),
          ends_on: Date.new(2026, 4, 14),
          available_slots: 40,
          registrations: [
            {
              user_email: Seeds::AuthCore::PRIMARY_EMAIL,
              quantity: 1,
              payment_method: TemplePayment::PAYMENT_METHODS[:cash],
              payment_reference: "PMT-LTS-001",
              contact_name: "Demo Client",
              contact_phone: "02-2222-5888"
            }
          ]
        },
        {
          slug: "lotus-light",
          offering_type: TempleOffering::OFFERING_TYPES[:lamp],
          title: "蓮花光明燈",
          description: "全年供燈並附上書法祈願卡。",
          price_cents: 2800,
          currency: "TWD",
          available_slots: 80,
          registrations: []
        }
      ]
    }.freeze

    def seed
      puts "Seeding temple offerings/payments..." # rubocop:disable Rails/Output
      OFFERINGS.each do |slug, entries|
        temple = Temple.find_by(slug:)
        next unless temple

        entries.each do |offering_attrs|
          offering = ensure_offering(temple, offering_attrs)
          Array(offering_attrs[:registrations]).each do |registration_attrs|
            ensure_registration(temple, offering, registration_attrs)
          end
        end
      end
    end

    private

    def ensure_offering(temple, attrs)
      temple.temple_offerings.find_or_initialize_by(slug: attrs[:slug]).tap do |offering|
        offering.assign_attributes(
          offering_type: attrs[:offering_type],
          title: attrs[:title],
          description: attrs[:description],
          price_cents: attrs[:price_cents],
          currency: attrs[:currency],
          period: attrs[:period],
          starts_on: attrs[:starts_on],
          ends_on: attrs[:ends_on],
          available_slots: attrs[:available_slots],
          active: true,
          metadata: (offering.metadata || {}).merge(seed_metadata)
        )
        offering.temple = temple
        offering.save!
      end
    end

    def ensure_registration(temple, offering, attrs)
      user = User.find_by(email: attrs[:user_email])
      unit_price = attrs[:unit_price_cents] || offering.price_cents
      quantity = attrs[:quantity] || 1
      total_price = attrs[:total_price_cents] || unit_price * quantity
      currency = attrs[:currency] || offering.currency
      contact_payload = {
        "name" => attrs[:contact_name] || user&.english_name || "Demo Patron",
        "phone" => attrs[:contact_phone] || "02-1234-5678"
      }.compact

      registration = temple.temple_event_registrations.find_or_initialize_by(
        reference_code: attrs[:reference_code] || "REG-#{SecureRandom.hex(3).upcase}"
      )
      registration.assign_attributes(
        temple_offering: offering,
        temple: temple,
        user: user,
        event_slug: offering.slug,
        quantity: quantity,
        unit_price_cents: unit_price,
        total_price_cents: total_price,
        currency: currency,
        contact_payload: contact_payload,
        payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending],
        fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
        metadata: (registration.metadata || {}).merge(seed_metadata)
      )
      registration.save!

      if attrs[:payment_method]
        ensure_payment(registration, attrs)
        registration.update!(payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid])
      end

      registration
    end

    def ensure_payment(registration, attrs)
      temple = registration.temple
      payment = registration.temple_payments.find_or_initialize_by(
        external_reference: attrs[:payment_reference] || "PMT-#{SecureRandom.hex(3).upcase}"
      )
      payment.assign_attributes(
        temple: temple,
        user: registration.user,
        temple_event_registration: registration,
        payment_method: attrs[:payment_method],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: attrs[:amount_cents] || registration.total_price_cents,
        currency: attrs[:currency] || registration.currency,
        processed_at: attrs[:processed_at] || Time.current,
        metadata: (payment.metadata || {}).merge(seed_metadata)
      )
      payment.save!
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:temple_financials"
      }
    end
  end
end
