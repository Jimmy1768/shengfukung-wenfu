# frozen_string_literal: true

module TempleContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_temple if respond_to?(:helper_method)
  end

  def current_temple
    @current_temple ||= begin
      slug = resolved_temple_slug
      if admin_temple_context?
        scoped = Temple.for_admin(current_admin.admin_account)
        resolve_temple_from_scope(scoped, slug)
      else
        resolve_temple_from_scope(Temple.all, slug)
      end
    end
  end

  private

  def resolve_temple_from_scope(scope, slug)
    temple =
      find_temple(scope, slug) ||
      find_temple(scope, AppConstants::Project.slug) ||
      scope.first

    return unless temple

    Temple.includes(temple_pages: :temple_sections).find_by(id: temple.id) || temple
  end

  def find_temple(scope, slug)
    return if slug.blank?

    scope.find_by(slug: slug)
  end

  def resolved_temple_slug
    slug =
      params[:temple_slug].presence ||
      params[:slug].presence ||
      params[:temple].presence
    return slug if slug.present?

    if respond_to?(:admin_selected_temple_slug, true)
      selected = admin_selected_temple_slug
      return selected if selected.present?
    end

    if respond_to?(:active_temple_slug, true)
      selected = active_temple_slug
      return selected if selected.present?
    end

    AppConstants::Project.slug
  end

  def admin_temple_context?
    respond_to?(:current_admin, true) && current_admin&.admin_account.present?
  end
end
