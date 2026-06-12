# frozen_string_literal: true

module Offerings
  class SetupFieldCatalog
    Field = Struct.new(:key, :label, :hint, :group, :kind, :option_bearing, keyword_init: true) do
      def option_bearing? = option_bearing
    end
    RegistrationField = Struct.new(:key, :label, :hint, :section, :kind, keyword_init: true)

    FIELDS = [
      Field.new(
        key: "price_cents",
        label: "金額",
        hint: "供品或服務的基本金額。",
        group: "basic",
        kind: "number",
        option_bearing: false
      ),
      Field.new(
        key: "currency",
        label: "幣別",
        hint: "供品或服務收款使用的幣別。",
        group: "basic",
        kind: "select",
        option_bearing: true
      ),
      Field.new(
        key: "description",
        label: "說明文字",
        hint: "供品或服務頁面顯示的內容說明。",
        group: "basic",
        kind: "text",
        option_bearing: false
      ),
      Field.new(
        key: "fulfillment_method",
        label: "辦理方式",
        hint: "例如廟方代辦、現場確認、親領等作業方式。",
        group: "operations",
        kind: "select",
        option_bearing: true
      ),
      Field.new(
        key: "logistics_notes",
        label: "作業備註",
        hint: "提供給工作人員的物流、領取或辦理提醒。",
        group: "operations",
        kind: "text",
        option_bearing: false
      ),
      Field.new(
        key: "lamp_type",
        label: "燈別",
        hint: "點燈服務可選擇的燈種。",
        group: "lamp",
        kind: "select",
        option_bearing: true
      ),
      Field.new(
        key: "lamp_location",
        label: "燈位位置",
        hint: "記錄燈位、區域或安奉位置。",
        group: "lamp",
        kind: "text",
        option_bearing: false
      ),
      Field.new(
        key: "blessing_target_type",
        label: "祈福對象",
        hint: "法會或供品的對象類別，例如斗別或祈福項目。",
        group: "ritual",
        kind: "select",
        option_bearing: true
      ),
      Field.new(
        key: "certificate_hint",
        label: "證書提示",
        hint: "證書或收據相關的內部提示。",
        group: "certificate",
        kind: "text",
        option_bearing: false
      ),
      Field.new(
        key: "blessing_names",
        label: "祈福姓名",
        hint: "填寫需要祈福或登記的姓名。",
        group: "ritual",
        kind: "text",
        option_bearing: false
      ),
      Field.new(
        key: "table_size",
        label: "供桌尺寸",
        hint: "供桌服務可選擇的尺寸或類型。",
        group: "table",
        kind: "select",
        option_bearing: true
      ),
      Field.new(
        key: "table_items",
        label: "供桌內容",
        hint: "記錄供桌包含的物品或備註。",
        group: "table",
        kind: "text",
        option_bearing: false
      )
    ].freeze

    REGISTRATION_FIELDS = [
      RegistrationField.new(
        key: "quantity",
        label: "數量",
        hint: "供品或服務的登記數量。",
        section: "order",
        kind: "number"
      ),
      RegistrationField.new(
        key: "unit_price_cents",
        label: "單價",
        hint: "現場可調整或確認的單筆金額。",
        section: "order",
        kind: "number"
      ),
      RegistrationField.new(
        key: "currency",
        label: "幣別",
        hint: "訂單收款幣別。",
        section: "order",
        kind: "select"
      ),
      RegistrationField.new(
        key: "certificate_number",
        label: "證書號碼",
        hint: "需要先填或補登證書編號時使用。",
        section: "order",
        kind: "text"
      ),
      RegistrationField.new(
        key: "primary_contact",
        label: "主要聯絡人",
        hint: "負責確認本筆登記的聯絡人。",
        section: "contact",
        kind: "text"
      ),
      RegistrationField.new(
        key: "phone",
        label: "電話",
        hint: "聯絡電話。",
        section: "contact",
        kind: "text"
      ),
      RegistrationField.new(
        key: "email",
        label: "電子郵件",
        hint: "聯絡信箱。",
        section: "contact",
        kind: "text"
      ),
      RegistrationField.new(
        key: "dependents_notes",
        label: "家庭／眷屬",
        hint: "同戶成員、眷屬或代辦關係。",
        section: "contact",
        kind: "textarea"
      ),
      RegistrationField.new(
        key: "notes",
        label: "聯絡備註",
        hint: "其他聯絡或受理備註。",
        section: "contact",
        kind: "textarea"
      ),
      RegistrationField.new(
        key: "preferred_date",
        label: "首選日期",
        hint: "信眾偏好的辦理日期。",
        section: "logistics",
        kind: "date"
      ),
      RegistrationField.new(
        key: "preferred_slot",
        label: "首選時段",
        hint: "例如上午、下午、晚上。",
        section: "logistics",
        kind: "text"
      ),
      RegistrationField.new(
        key: "arrival_window",
        label: "到場區間",
        hint: "到場或取件時間範圍。",
        section: "logistics",
        kind: "text"
      ),
      RegistrationField.new(
        key: "ceremony_location",
        label: "法會地點",
        hint: "儀式或服務辦理位置。",
        section: "logistics",
        kind: "text"
      ),
      RegistrationField.new(
        key: "ancestor_placard_name",
        label: "祖先牌位姓名",
        hint: "超薦、牌位或祖先相關登記姓名。",
        section: "ritual_metadata",
        kind: "text"
      ),
      RegistrationField.new(
        key: "dedication_message",
        label: "祈福語",
        hint: "祝禱、迴向或祈福文字。",
        section: "ritual_metadata",
        kind: "textarea"
      ),
      RegistrationField.new(
        key: "incense_option",
        label: "香支選項",
        hint: "香、金紙或儀式選項。",
        section: "ritual_metadata",
        kind: "text"
      ),
      RegistrationField.new(
        key: "certificate_notes",
        label: "證書備註",
        hint: "證書列印或交付提醒。",
        section: "ritual_metadata",
        kind: "textarea"
      )
    ].freeze

    DEFAULT_REGISTRATION_FIELDS = {
      "order" => %w[quantity unit_price_cents currency],
      "contact" => %w[primary_contact phone email notes],
      "logistics" => [],
      "ritual_metadata" => []
    }.freeze

    def self.fields
      FIELDS
    end

    def self.find(key)
      fields.find { |field| field.key == key.to_s }
    end

    def self.supported?(key)
      find(key).present?
    end

    def self.option_bearing?(key)
      find(key)&.option_bearing? || false
    end

    def self.supported_keys
      fields.map(&:key)
    end

    def self.option_bearing_keys
      fields.select(&:option_bearing?).map(&:key)
    end

    def self.registration_field?(key)
      registration_fields.any? { |field| field.key == key.to_s }
    end

    def self.registration_fields
      REGISTRATION_FIELDS
    end

    def self.registration_field(section, key)
      registration_fields.find { |field| field.section == section.to_s && field.key == key.to_s }
    end

    def self.registration_field_supported?(section, key)
      registration_field(section, key).present?
    end

    def self.registration_grouped_fields
      registration_fields.group_by(&:section)
    end

    def self.registration_sections
      Registrations::FormSchema::DEFAULT_SECTIONS.keys.map(&:to_s)
    end

    def self.default_registration_fields
      DEFAULT_REGISTRATION_FIELDS.deep_dup
    end

    def self.grouped_fields
      fields.group_by(&:group)
    end
  end
end
