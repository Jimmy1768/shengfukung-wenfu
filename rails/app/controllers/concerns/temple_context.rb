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
      scoped = base_scope
      if respond_to?(:current_admin, true) && current_admin&.admin_account.present?
        scoped = scoped.merge(Temple.for_admin(current_admin.admin_account))
      end
      scoped.find_by(slug:) || base_scope.find_by(slug:) || base_scope.first
    end
  end

  private

  def resolved_temple_slug
    params[:temple_slug] || params[:slug] || AppConstants::Project.slug
  end
end
