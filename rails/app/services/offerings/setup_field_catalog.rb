# frozen_string_literal: true

module Offerings
  class SetupFieldCatalog
    Field = Struct.new(:key, :label, :hint, :group, :kind, :option_bearing, keyword_init: true) do
      def option_bearing? = option_bearing
    end

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

    REGISTRATION_FIELDS = Registrations::FormSchema::DEFAULT_SECTIONS.values.flatten.map(&:to_s).freeze

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
      REGISTRATION_FIELDS.include?(key.to_s)
    end

    def self.grouped_fields
      fields.group_by(&:group)
    end
  end
end
