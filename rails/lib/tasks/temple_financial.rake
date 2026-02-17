namespace :temple_financial do
  desc "Seed demo offerings for a temple slug"
  task :seed_offerings, [:slug] => :environment do |_, args|
    slug = args[:slug] || AppConstants::Project.slug
    temple = Temple.find_by!(slug:)
    loader = Offerings::TemplateLoader.new(slug)

    offerings = [
      { slug: "incense-donation", title: "香油捐獻", offering_type: "donation", price_cents: 500 },
      { slug: "family-peace", title: "平安戲丁口捐", offering_type: "ritual", price_cents: 800 },
      { slug: "lantern-lighting", title: "點燈作業", offering_type: "lamp", price_cents: 1200, available_slots: 50 },
      { slug: "ancestor-ritual", title: "祖先拔薦", offering_type: "ritual", price_cents: 1500 },
      { slug: "pudu-table", title: "普渡供桌", offering_type: "table", price_cents: 3000, available_slots: 100, period: "Ghost Festival" }
    ]

    offerings.each do |attrs|
      template = loader.template_for(attrs[:slug])
      kind = template&.dig(:kind)&.to_sym || :event
      metadata_target = {}

      if template
        metadata_target["form_fields"] = template[:form_fields] if template[:form_fields]
        metadata_target["form_defaults"] = template[:defaults] if template[:defaults]
        metadata_target["form_options"] = template[:options] if template[:options]
        metadata_target["form_label"] = template[:label] if template[:label]
        metadata_target["registration_form"] = template[:registration_form] if template[:registration_form]
      end

      record =
        if kind == :service
          temple.temple_services.find_or_initialize_by(slug: attrs[:slug])
        else
          TempleOffering.find_or_initialize_by(temple:, slug: attrs[:slug])
        end

      metadata = (record.metadata || {}).merge(metadata_target)
      assignment = attrs.slice(:title, :description, :price_cents, :currency, :status)
      assignment[:currency] ||= "TWD"
      assignment[:status] ||= "published"

      if kind == :service
        assignment[:quantity_limit] = attrs[:available_slots] if attrs[:available_slots]
        assignment[:available_from] = attrs[:available_from]
        assignment[:available_until] = attrs[:available_until]
      else
        assignment[:starts_on] = attrs[:starts_on] || Date.current
        assignment[:ends_on] = attrs[:ends_on] || assignment[:starts_on]
        assignment[:available_slots] = attrs[:available_slots] if attrs[:available_slots]
        assignment[:period] = attrs[:period] || "#{assignment[:starts_on]} – #{assignment[:ends_on]}"
      end

      record.assign_attributes(assignment.merge(metadata: metadata))
      record.save!
    end

    puts "Seeded financial offerings for #{temple.name}."
  end

  desc "Grant full financial permissions to an admin email for a temple"
  task :grant_permissions, %i[slug email] => :environment do |_, args|
    slug = args[:slug] || AppConstants::Project.slug
    email = args[:email] || ENV.fetch("PROJECT_DEFAULT_ADMIN_EMAIL")

    temple = Temple.find_by!(slug:)
    user = User.find_by!(email:)
    admin_account = user.admin_account || AdminAccount.create!(user:, role: "owner")

    AdminTempleMembership.find_or_create_by!(admin_account:, temple:) do |membership|
      membership.role = "owner"
    end

    permission = AdminPermission.find_or_initialize_by(admin_account:, temple:)
    permission.assign_attributes(
      manage_offerings: true,
      manage_registrations: true,
      record_cash_payments: true,
      view_financials: true,
      export_financials: true,
      view_guest_lists: true,
      manage_permissions: true
    )
    permission.save!

    puts "Granted financial permissions for #{email} on #{temple.name}."
  end
end
