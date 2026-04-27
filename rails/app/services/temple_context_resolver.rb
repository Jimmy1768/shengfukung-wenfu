# frozen_string_literal: true

class TempleContextResolver
  ADMIN_TEMPLE_SESSION_KEY = AppConstants::Sessions.key(:admin_temple)
  ACCOUNT_TEMPLE_SESSION_KEY = "account_active_temple_slug"

  Result = Struct.new(:temple, :slug, :source, keyword_init: true) do
    def valid?
      temple.present?
    end
  end

  def initialize(params:, session:, surface:, admin_account: nil, active_temple_slug: nil)
    @params = params
    @session = session || {}
    @surface = surface.to_sym
    @admin_account = admin_account
    @active_temple_slug = active_temple_slug
  end

  def resolve
    scope = temple_scope
    temple, slug, source = resolve_from_candidates(scope)
    temple ||= scope.first

    Result.new(
      temple: hydrate(temple),
      slug: temple&.slug || slug,
      source: temple.present? ? (source || :scope_fallback) : nil
    )
  end

  private

  attr_reader :params, :session, :surface, :admin_account, :active_temple_slug

  def temple_scope
    return Temple.for_admin(admin_account) if surface == :admin && admin_account.present?

    Temple.all
  end

  def resolve_from_candidates(scope)
    context_candidates.each do |candidate|
      temple = find_temple(scope, candidate[:slug])
      return [temple, candidate[:slug], candidate[:source]] if temple
    end

    [nil, context_candidates.first&.dig(:slug), nil]
  end

  def context_candidates
    @context_candidates ||= begin
      entries =
        case surface
        when :admin
          admin_candidates
        when :account
          account_candidates
        else
          public_candidates
        end

      entries.filter_map do |source, slug|
        normalized = normalize_slug(slug)
        { source:, slug: normalized } if normalized.present?
      end.uniq { |entry| entry[:slug] }
    end
  end

  def admin_candidates
    [
      [:request_temple_slug, params[:temple_slug]],
      [:request_tenant_slug, params[:tenant_slug]],
      [:session_admin_temple_slug, session[ADMIN_TEMPLE_SESSION_KEY]],
      [:project_default, AppConstants::Project.slug]
    ]
  end

  def account_candidates
    [
      [:request_temple_slug, params[:temple_slug]],
      [:request_tenant_slug, params[:tenant_slug]],
      [:legacy_request_temple, params[:temple]],
      [:active_temple_slug, active_temple_slug],
      [:session_account_temple_slug, session[ACCOUNT_TEMPLE_SESSION_KEY]],
      [:project_default, AppConstants::Project.slug]
    ]
  end

  def public_candidates
    [
      [:request_temple_slug, params[:temple_slug]],
      [:request_tenant_slug, params[:tenant_slug]],
      [:route_slug, params[:slug]],
      [:project_default, AppConstants::Project.slug]
    ]
  end

  def find_temple(scope, slug)
    return if slug.blank?

    scope.find_by(slug: slug)
  end

  def hydrate(temple)
    return unless temple

    Temple.includes(temple_pages: :temple_sections).find_by(id: temple.id) || temple
  end

  def normalize_slug(value)
    return unless value.respond_to?(:to_str)

    value.to_str.strip.presence
  end
end
