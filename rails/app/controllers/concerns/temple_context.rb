# frozen_string_literal: true

module TempleContext
  extend ActiveSupport::Concern

  included do
    helper_method :current_temple if respond_to?(:helper_method)
  end

  def current_temple
    temple_context.temple
  end

  def temple_context
    @temple_context ||= TempleContextResolver.new(
      params: params,
      session: context_session,
      surface: temple_context_surface,
      admin_account: admin_temple_context? ? current_admin.admin_account : nil,
      active_temple_slug: context_active_temple_slug
    ).resolve
  end

  private

  def temple_context_surface
    return :admin if admin_temple_context?
    return :account if respond_to?(:active_temple_slug, true)

    :public
  end

  def context_active_temple_slug
    return unless respond_to?(:active_temple_slug, true)

    active_temple_slug
  end

  def context_session
    respond_to?(:session, true) ? session : {}
  end

  def resolved_temple_slug
    temple_context.slug
  end

  def temple_slug_param(value)
    return unless value.respond_to?(:to_str)

    value.to_str.strip.presence
  end

  def admin_temple_context?
    respond_to?(:current_admin, true) && current_admin&.admin_account.present?
  end
end
