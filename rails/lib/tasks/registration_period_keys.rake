# frozen_string_literal: true

require "json"
require "yaml"

module RegistrationPeriodKeyGovernance
  module_function

  def temples_for_scope(slug_value)
    slugs = slug_value.to_s.split(",").map(&:strip).reject(&:blank?)
    scope = slugs.any? ? Temple.where(slug: slugs) : Temple.all
    scope.order(:slug)
  end

  def invalid_service_scope(temple)
    scope = temple.temple_services.where.not(registration_period_key: [nil, ""])
    allowed = temple.registration_period_keys
    allowed.any? ? scope.where.not(registration_period_key: allowed) : scope
  end

  def invalid_registration_scope(temple)
    scope = temple.temple_event_registrations.where("COALESCE(metadata ->> 'registration_period_key', '') <> ''")
    allowed = temple.registration_period_keys
    return scope unless allowed.any?

    scope.where.not("metadata ->> 'registration_period_key' IN (?)", allowed)
  end

  def boolean_env(key, default: false)
    return default unless ENV.key?(key)

    ActiveModel::Type::Boolean.new.cast(ENV[key])
  end
end

namespace :registration_period_keys do
  desc "Audit services/registrations using period keys missing from temple YAML"
  task audit: :environment do
    report = []

    RegistrationPeriodKeyGovernance.temples_for_scope(ENV["SLUG"]).find_each do |temple|
      invalid_services = RegistrationPeriodKeyGovernance.invalid_service_scope(temple)
      invalid_registrations = RegistrationPeriodKeyGovernance.invalid_registration_scope(temple)

      service_rows = invalid_services.order(:id).map do |service|
        {
          service_id: service.id,
          service_slug: service.slug,
          service_title: service.title,
          registration_period_key: service.registration_period_key
        }
      end
      registration_rows = invalid_registrations.order(:id).map do |registration|
        {
          registration_id: registration.id,
          reference_code: registration.reference_code,
          registrable_type: registration.registrable_type,
          registrable_id: registration.registrable_id,
          registration_period_key: registration.metadata.to_h["registration_period_key"],
          created_at: registration.created_at&.iso8601
        }
      end

      report << {
        temple_slug: temple.slug,
        allowed_period_keys: temple.registration_period_keys,
        invalid_service_count: service_rows.size,
        invalid_registration_count: registration_rows.size,
        invalid_services: service_rows,
        invalid_registrations: registration_rows
      }
    end

    total_services = report.sum { |entry| entry[:invalid_service_count] }
    total_registrations = report.sum { |entry| entry[:invalid_registration_count] }
    puts "Audit complete: invalid services=#{total_services}, invalid registrations=#{total_registrations}"
    report.each do |entry|
      next if entry[:invalid_service_count].zero? && entry[:invalid_registration_count].zero?

      puts "#{entry[:temple_slug]} => services=#{entry[:invalid_service_count]}, registrations=#{entry[:invalid_registration_count]}"
    end

    output_path = ENV["OUTPUT"].to_s.strip
    if output_path.present?
      File.write(output_path, JSON.pretty_generate(report))
      puts "Wrote remediation list to #{output_path}"
    end
  end

  desc "Remap invalid period keys to a fallback key (dry-run by default, set APPLY=true to persist)"
  task remap_invalid: :environment do
    fallback_key = ENV["FALLBACK_KEY"].to_s.strip
    abort "FALLBACK_KEY is required" if fallback_key.blank?

    apply_changes = RegistrationPeriodKeyGovernance.boolean_env("APPLY", default: false)
    remap_registrations = RegistrationPeriodKeyGovernance.boolean_env("INCLUDE_REGISTRATIONS", default: true)

    total_service_updates = 0
    total_registration_updates = 0
    now = Time.current

    RegistrationPeriodKeyGovernance.temples_for_scope(ENV["SLUG"]).find_each do |temple|
      unless temple.registration_period_keys.include?(fallback_key)
        puts "[skip] #{temple.slug}: fallback key '#{fallback_key}' not found in temple registration_periods"
        next
      end

      fallback_label = temple.registration_period_label_for(fallback_key)
      services = RegistrationPeriodKeyGovernance.invalid_service_scope(temple).order(:id)
      registrations = remap_registrations ? RegistrationPeriodKeyGovernance.invalid_registration_scope(temple).order(:id) : TempleEventRegistration.none

      puts "#{temple.slug}: services=#{services.count}, registrations=#{registrations.count}, apply=#{apply_changes}"
      next unless apply_changes

      TempleService.transaction do
        services.find_each do |service|
          metadata = (service.metadata || {}).with_indifferent_access
          old_key = service.registration_period_key.to_s
          legacy_keys = Array(metadata["legacy_registration_period_keys"]).map(&:to_s)
          legacy_keys << old_key unless legacy_keys.include?(old_key)
          metadata["legacy_registration_period_keys"] = legacy_keys

          service.update_columns(
            registration_period_key: fallback_key,
            period_label: fallback_label,
            metadata: metadata,
            updated_at: now
          )
          total_service_updates += 1
        end

        registrations.find_each do |registration|
          metadata = (registration.metadata || {}).with_indifferent_access
          old_key = metadata["registration_period_key"].to_s
          legacy_keys = Array(metadata["legacy_registration_period_keys"]).map(&:to_s)
          legacy_keys << old_key unless legacy_keys.include?(old_key)
          metadata["legacy_registration_period_keys"] = legacy_keys
          metadata["registration_period_key"] = fallback_key

          registration.update_columns(metadata: metadata, updated_at: now)
          total_registration_updates += 1
        end
      end
    end

    if apply_changes
      puts "Remap complete: updated services=#{total_service_updates}, registrations=#{total_registration_updates}"
    else
      puts "Dry-run only. Re-run with APPLY=true to persist changes."
    end
  end

  desc "Roll registration period keys/labels forward by one year (dry-run by default, set WRITE=true to persist)"
  task rollover_year: :environment do
    write_changes = RegistrationPeriodKeyGovernance.boolean_env("WRITE", default: false)
    update_services = RegistrationPeriodKeyGovernance.boolean_env("UPDATE_SERVICES", default: false)
    if update_services && !write_changes
      abort "UPDATE_SERVICES=true requires WRITE=true"
    end

    result = Registrations::PeriodKeyRollover.call(
      slug: ENV["SLUG"],
      write: write_changes,
      update_services: update_services
    )

    total_errors = 0
    total_updated_keys = 0
    total_service_updates = 0

    result.fetch(:results).each do |entry|
      errors = Array(entry[:errors])
      updated_keys = entry.fetch(:updated_keys, {})
      skipped = entry.fetch(:skipped_keys, [])

      total_errors += errors.size
      total_updated_keys += updated_keys.size
      total_service_updates += entry.fetch(:service_updates, 0).to_i

      puts "#{entry[:temple_slug]}: updated_keys=#{updated_keys.size} skipped=#{skipped.size} service_updates=#{entry[:service_updates]} errors=#{errors.size}"
      errors.each { |error| puts "  error: #{error}" }
    end

    puts "Rollover #{write_changes ? 'apply' : 'dry-run'} complete: temples=#{result[:temple_count]} updated_keys=#{total_updated_keys} service_updates=#{total_service_updates} errors=#{total_errors}"

    output_path = ENV["OUTPUT"].to_s.strip
    if output_path.present?
      File.write(output_path, JSON.pretty_generate(result))
      puts "Wrote rollover report to #{output_path}"
    end

    abort "Rollover failed with #{total_errors} error(s)." if total_errors.positive?
    puts "Dry-run only. Re-run with WRITE=true to persist YAML changes." unless write_changes
  end
end
