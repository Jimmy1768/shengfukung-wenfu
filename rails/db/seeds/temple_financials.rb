# frozen_string_literal: true

require "securerandom"

module Seeds
  module TempleFinancials
    extend self

    OFFERINGS = {
      "shenfukung-wenfu" => [
        {
          slug: "lantern-lighting",
          kind: :event,
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
          slug: "spring-blessing-rite",
          kind: :event,
          offering_type: TempleOffering::OFFERING_TYPES[:ritual],
          title: "春季祈安法會",
          description: "法師帶領誦經迴向，祈求闔家平安與事業順利。",
          price_cents: 2000,
          currency: "TWD",
          period: "春季祈福",
          starts_on: Date.new(2026, 2, 15),
          ends_on: Date.new(2026, 3, 30),
          available_slots: 90,
          location_name: "正殿",
          location_address: "新北市中和區福真街 108 號",
          registrations: []
        },
        {
          slug: "pudu-table",
          kind: :service,
          offering_type: TempleOffering::OFFERING_TYPES[:table],
          title: "普渡供桌",
          description: "含水果、鮮花與供品，可於指定檔期代為佈置。",
          price_cents: 5000,
          currency: "TWD",
          period: "中元普渡",
          available_from: Date.new(2026, 7, 1),
          available_until: Date.new(2026, 8, 15),
          available_slots: 160,
          default_location: "普渡供桌區",
          fulfillment_notes: "供桌擺設由廟方統一安排，報名後由志工聯繫。",
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
        },
        {
          slug: "year-round-blessing",
          kind: :service,
          offering_type: TempleOffering::OFFERING_TYPES[:donation],
          title: "全年祈福服務",
          description: "祈福服務採全年受理，依祈願內容安排祭解與迴向。",
          price_cents: 1200,
          currency: "TWD",
          period: "全年",
          available_from: Date.new(2026, 1, 1),
          available_until: Date.new(2026, 12, 31),
          available_slots: 500,
          default_location: "服務台",
          fulfillment_notes: "可備註祈願事項，法會前由服務台確認。"
        }
      ],
      "demo-lotus" => [
        {
          slug: "meditation-retreat",
          kind: :event,
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
          kind: :service,
          offering_type: TempleOffering::OFFERING_TYPES[:lamp],
          title: "蓮花光明燈",
          description: "全年供燈並附上書法祈願卡。",
          price_cents: 2800,
          currency: "TWD",
          period: "全年",
          available_from: Date.new(2026, 1, 1),
          available_until: Date.new(2026, 12, 31),
          available_slots: 80,
          default_location: "祈福櫃台",
          fulfillment_notes: "完成報名後，三日內點燈並通知。",
          registrations: []
        }
      ]
    }.freeze

    GATHERINGS = {
      "shenfukung-wenfu" => [
        {
          slug: "first-aid-workshop",
          title: "社群聚會：寺院急救工作坊",
          subtitle: "與社區醫護合作的公益課程",
          description: "社群聚會邀請資深護理師分享急救步驟，課後提供演練指引。",
          starts_on: Date.new(2026, 5, 10),
          ends_on: Date.new(2026, 5, 10),
          start_time: Time.zone.parse("09:00"),
          end_time: Time.zone.parse("12:00"),
          location_name: "大殿旁研習教室",
          location_address: "新北市中和區福真街 108 號",
          price_cents: 600,
          currency: "TWD",
          status: "published"
        },
        {
          slug: "community-tea-night",
          title: "社群聚會：茶敘共修夜",
          subtitle: "開放新舊會員交流",
          description: "以輕鬆對談與共修方式，介紹近期法會活動與祈福服務。",
          starts_on: Date.new(2026, 3, 20),
          ends_on: Date.new(2026, 3, 20),
          start_time: Time.zone.parse("19:00"),
          end_time: Time.zone.parse("21:00"),
          location_name: "活動教室",
          location_address: "新北市中和區福真街 108 號",
          price_cents: 0,
          currency: "TWD",
          status: "published",
          free_gathering: true
        }
      ],
      "demo-lotus" => [
        {
          slug: "calligraphy-gathering",
          title: "社群聚會：禪書共修",
          subtitle: "結合抄經與音樂療癒",
          description: "社群聚會結合抄經與音樂療癒，附茶點與器材使用。",
          starts_on: Date.new(2026, 6, 2),
          ends_on: Date.new(2026, 6, 2),
          start_time: Time.zone.parse("19:00"),
          end_time: Time.zone.parse("21:00"),
          location_name: "蓮城慈航宮禪修室",
          location_address: "新北市中和區蓮城路 88 號",
          price_cents: 800,
          currency: "TWD",
          status: "published"
        }
      ]
    }.freeze

    def seed
      puts "Seeding temple offerings/payments..." # rubocop:disable Rails/Output
      seed_offerings
      seed_gatherings
    end

    private

    def seed_offerings
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

    def seed_gatherings
      GATHERINGS.each do |slug, entries|
        temple = Temple.find_by(slug:)
        next unless temple

        entries.each do |gathering_attrs|
          ensure_gathering(temple, gathering_attrs)
        end
      end
    end

    def ensure_offering(temple, attrs)
      kind = (attrs[:kind] || :event).to_sym
      scope =
        case kind
        when :service then temple.temple_services
        else temple.temple_events
        end
      scope.find_or_initialize_by(slug: attrs[:slug]).tap do |offering|
        starts_on = attrs[:starts_on] || Date.new(2026, 1, 1)
        ends_on = attrs[:ends_on] || starts_on + 30
        period = attrs[:period].presence || "#{starts_on.strftime('%Y/%m/%d')} – #{ends_on.strftime('%Y/%m/%d')}"

        offering.assign_attributes(
          title: attrs[:title],
          description: attrs[:description],
          price_cents: attrs[:price_cents],
          currency: attrs[:currency],
          status: attrs[:status] || "published",
          metadata: (offering.metadata || {}).merge(seed_metadata)
        )
        if kind == :service
          offering.period_label = period
          offering.available_from = attrs[:available_from] || starts_on
          offering.available_until = attrs[:available_until] || ends_on
          offering.quantity_limit = attrs[:available_slots]
          offering.registration_period_key = attrs[:registration_period_key] if attrs[:registration_period_key].present?
          offering.default_location = attrs[:default_location]
          offering.fulfillment_notes = attrs[:fulfillment_notes]
        else
          offering.assign_attributes(
            starts_on: starts_on,
            ends_on: ends_on,
            location_name: attrs[:location_name],
            location_address: attrs[:location_address],
            location_notes: attrs[:location_notes],
            capacity_total: attrs[:available_slots]
          )
          offering.period = period
        end
        offering.offering_type = attrs[:offering_type] if offering.respond_to?(:offering_type=) && attrs[:offering_type].present?
        offering.available_slots = attrs[:available_slots] if offering.respond_to?(:available_slots=)
        offering.temple = temple
        offering.save!
      end
    end

    def ensure_gathering(temple, attrs)
      TempleGathering.find_or_initialize_by(temple:, slug: attrs[:slug]).tap do |gathering|
        metadata = (gathering.metadata || {}).merge(seed_metadata)
        metadata["free_gathering"] = true if attrs[:free_gathering]
        gathering.assign_attributes(
          title: attrs[:title],
          subtitle: attrs[:subtitle],
          description: attrs[:description],
          starts_on: attrs[:starts_on],
          ends_on: attrs[:ends_on] || attrs[:starts_on],
          start_time: attrs[:start_time],
          end_time: attrs[:end_time],
          location_name: attrs[:location_name],
          location_address: attrs[:location_address],
          location_notes: attrs[:location_notes],
          price_cents: attrs[:price_cents] || 0,
          currency: attrs[:currency] || "TWD",
          status: attrs[:status] || "draft",
          metadata: metadata
        )
        gathering.save!
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

      code = attrs[:reference_code].presence || generated_reference
      registration = TempleRegistration.find_or_initialize_by(reference_code: code, temple:)
      registration.assign_attributes(
        registrable: offering,
        temple: temple,
        user: user,
        quantity: quantity,
        unit_price_cents: unit_price,
        total_price_cents: total_price,
        currency: currency,
        contact_payload: contact_payload,
        payment_status: TempleRegistration::PAYMENT_STATUSES[:pending],
        fulfillment_status: TempleRegistration::FULFILLMENT_STATUSES[:open],
        metadata: (registration.metadata || {}).merge(seed_metadata).merge("event_slug" => offering.slug)
      )
      registration.save!

      if attrs[:payment_method]
        ensure_payment(registration, attrs)
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:paid])
      end

      registration
    end

    def ensure_payment(registration, attrs)
      temple = registration.temple
      external = attrs[:payment_reference].presence || generated_payment_reference
      payment = TemplePayment.find_by(external_reference: external) ||
        registration.temple_payments.build(external_reference: external)
      payment.assign_attributes(
        temple: temple,
        user: registration.user,
        temple_registration: registration,
        provider: attrs[:provider] || "demo",
        provider_account: attrs[:provider_account] || "temple",
        provider_reference: attrs[:provider_reference],
        payment_method: attrs[:payment_method],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: attrs[:amount_cents] || registration.total_price_cents,
        currency: attrs[:currency] || registration.currency,
        processed_at: attrs[:processed_at] || Time.current,
        metadata: (payment.metadata || {}).merge(seed_metadata)
      )
      payment.save!
    end

    def generated_reference
      "REG-#{SecureRandom.hex(3).upcase}"
    end

    def generated_payment_reference
      "PMT-#{SecureRandom.hex(3).upcase}"
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:temple_financials"
      }
    end
  end
end
