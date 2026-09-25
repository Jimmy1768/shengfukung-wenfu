# frozen_string_literal: true

namespace :offerings do
  desc "Create (if missing) and sync every offering template in db/temples/offerings/<slug>.yml as a real, published offering"
  task :apply_templates, [:slug] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    temple = Temple.find_by!(slug:)
    loader = Offerings::TemplateLoader.new(temple.slug)

    created = []
    already_present = []

    loader.services.each do |template|
      existing = temple.temple_services.find_by(slug: template[:slug])
      if existing
        already_present << template[:slug]
        next
      end

      temple.temple_services.create!(
        slug: template[:slug],
        title: template[:label],
        status: "published",
        registration_period_key: template[:registration_period_key],
        price_cents: template.dig(:attributes, :price_cents),
        currency: template.dig(:attributes, :currency)
      )
      created << template[:slug]
    end

    loader.events.each do |template|
      existing = temple.temple_events.find_by(slug: template[:slug])
      if existing
        already_present << template[:slug]
        next
      end

      temple.temple_events.create!(
        slug: template[:slug],
        title: template[:label],
        status: "published",
        price_cents: template.dig(:attributes, :price_cents),
        currency: template.dig(:attributes, :currency)
      )
      created << template[:slug]
    end

    # TemplateSync only updates offerings that already exist by slug -- run
    # it after creation so every template (newly created just now, or
    # already present from a prior run) ends up with the full metadata
    # (registration_form, form_fields, options, etc.) the YAML declares,
    # not just the bare attributes set above.
    result = Offerings::TemplateSync.call(temple)

    SystemAuditLogger.log!(
      action: "offerings.templates_applied",
      temple:,
      metadata: {
        created:,
        already_present:,
        synced_services: result.updated_services,
        synced_events: result.updated_events
      }
    )

    puts "#{slug}: created #{created.size} offering(s) #{created.inspect}, #{already_present.size} already present #{already_present.inspect}." # rubocop:disable Rails/Output
    puts "#{slug}: synced metadata for services #{result.updated_services.inspect}, events #{result.updated_events.inspect}." # rubocop:disable Rails/Output
  end

  # Onboarding generator for the per-(offering, field) `reuse:` policy.
  #
  # FormSchema's runtime default is a deliberate constant (:never) so reuse
  # behavior is never coupled to another field's value and is always readable
  # straight from the yml. This task is where the shape heuristic lives
  # instead: it proposes a policy per field once, at authoring time, so a
  # human can override it before it ships.
  #
  #   multi-value WITH temple options  -> never
  #       the menu is already complete, so remembering adds nothing to it,
  #       and these are selections (a purchase decision) rather than facts.
  #   multi-value WITHOUT options      -> offer_as_options
  #       the remembered values ARE the menu.
  #   single-value                     -> prefill
  #       short, visible, low risk, and it preserves "don't ask again".
  #
  #   bin/rails "offerings:annotate_reuse[shengfukung-demo]"          # preview
  #   bin/rails "offerings:annotate_reuse[shengfukung-demo,write]"    # apply
  desc "Propose reuse: policies for a temple's offering yml (preview unless 'write')"
  task :annotate_reuse, %i[slug mode] => :environment do |_task, args|
    slug = args[:slug].presence or abort("usage: offerings:annotate_reuse[<temple-slug>,(write)]")
    write = args[:mode].to_s == "write"
    path = Rails.root.join("db", "temples", "offerings", "#{slug}.yml")
    abort("no offering config at #{path}") unless File.exist?(path)

    doc = YAML.safe_load_file(path)
    offerings = doc["offerings"] || doc.values.find { |v| v.is_a?(Array) }
    abort("could not find an offerings list in #{path}") unless offerings

    changed = 0
    offerings.each do |offering|
      form = offering["registration_form"] || offering.dig("metadata", "registration_form")
      next if form.blank?

      schema = Registrations::FormSchema.new(form)
      settings = form["field_settings"] ||= {}

      reusable_candidates(form, schema).each do |field|
        current = settings[field]
        # A bare Array is shorthand for { options: [...] }; it cannot carry a
        # sibling key, so promote it before adding one.
        current = { "options" => current } if current.is_a?(Array)
        current = {} unless current.is_a?(Hash)
        next if current.key?("reuse")

        current["reuse"] = proposed_policy(schema, field).to_s
        settings[field] = current
        changed += 1
        puts format("  %-24s %-22s -> reuse: %s", offering["slug"], field, current["reuse"])
      end
    end

    if changed.zero?
      puts "No unannotated reusable fields found. Nothing to do."
    elsif write
      File.write(path, doc.to_yaml)
      puts "\nWrote #{changed} reuse: key(s) into #{path}."
      puts "Review them -- the heuristic is a starting point, not a decision."
    else
      puts "\n#{changed} field(s) would be annotated. Re-run with ,write to apply."
    end
  end

  # Reads the section's DECLARED fields straight from the yml rather than
  # through FormSchema#fields_for. FormSchema::normalize_field_config does
  # not handle the `{ fields: [...] }` shape every real temple config uses
  # (only a bare Array, which is what the tests use), so it silently returns
  # the full default field list. Annotating through it would write reuse:
  # keys for fields the offering never declared. That resolution bug is real
  # and separately reported; this generator must not depend on it either way.
  def reusable_candidates(form, schema)
    sections = form["sections"] || {}
    %w[logistics ritual_metadata]
      .flat_map { |section| declared_fields(sections[section]) }
      .map(&:to_s)
      .reject { |field| field.match?(Registrations::ReusableDefaults::TRANSIENT_KEY_PATTERN) }
      .reject { |field| Registrations::ReusableDefaults::FORBIDDEN_FIELDS.include?(field) }
      .uniq
  end

  def declared_fields(config)
    case config
    when Hash then Array(config["fields"] || config[:fields])
    when Array then config
    when false, nil then []
    else Registrations::FormSchema::DEFAULT_SECTIONS.values.flatten
    end
  end

  def proposed_policy(schema, field)
    return :prefill unless schema.allow_multiple?(field)
    return :never if schema.field_options(field).present?

    :offer_as_options
  end

end
