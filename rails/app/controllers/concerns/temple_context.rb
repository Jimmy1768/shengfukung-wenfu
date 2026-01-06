# frozen_string_literal: true

module TempleContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_temple if respond_to?(:helper_method)
  end

  def current_temple
    @current_temple ||= begin
      slug = resolved_temple_slug
      base_scope = Temple.includes(temple_pages: :temple_sections)
      if admin_temple_context?
        scoped = base_scope.merge(Temple.for_admin(current_admin.admin_account))
        scoped.find_by(slug:) || scoped.first
      else
        base_scope.find_by(slug:) || base_scope.find_by(slug: AppConstants::Project.slug) || base_scope.first
      end
    end
  end

  private

  def resolved_temple_slug
    slug = params[:temple_slug].presence || params[:slug].presence
    return slug if slug.present?

    if respond_to?(:admin_selected_temple_slug, true)
      selected = admin_selected_temple_slug
      return selected if selected.present?
    end

    AppConstants::Project.slug
  end

  def admin_temple_context?
    respond_to?(:current_admin, true) && current_admin&.admin_account.present?
  end
end
