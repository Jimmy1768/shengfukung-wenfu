# frozen_string_literal: true

module Admin
  class TemplesController < BaseController
    before_action :ensure_temple!
    before_action -> { require_capability!(:manage_profile) }
    skip_before_action :verify_authenticity_token, only: :update

    def edit
      @form = Admin::TempleProfileForm.new(temple: current_temple)
    end

    def update
      @form = Admin::TempleProfileForm.new(temple: current_temple, params: profile_params_with_uploads)

      if @form.save(current_admin:)
        redirect_to admin_temple_profile_path, notice: t("admin.temple_profile.flash.updated")
      else
        flash.now[:alert] = t("admin.temple_profile.flash.review_errors")
        render :edit, status: :unprocessable_entity
      end
    rescue MediaAssets::HeroImageUploader::UploadError => e
      @form = Admin::TempleProfileForm.new(temple: current_temple, params: temple_params)
      @form.errors.add(:hero_images, e.message)
      flash.now[:alert] = t("admin.temple_profile.flash.review_errors")
      render :edit, status: :unprocessable_entity
    end

    private

    def profile_params_with_uploads
      permitted = temple_params.to_h.deep_stringify_keys
      uploaded_urls = upload_hero_images
      return permitted if uploaded_urls.blank?

      permitted["hero_images"] = (permitted["hero_images"] || {}).merge(uploaded_urls)
      permitted
    end

    def upload_hero_images
      upload_params.each_with_object({}) do |(tab, file), urls|
        next if file.blank?

        result = MediaAssets::HeroImageUploader.call(
          temple: current_temple,
          file: file,
          hero_tab: tab,
          admin: current_admin
        )
        urls[tab.to_s] = result[:url]
      end
    end

    def upload_params
      raw = params.fetch(:hero_image_upload, {})
      raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h.slice(*Temple::HERO_TABS) : {}
    end

    def temple_params
      params.require(:temple).permit(
        :name,
        :tagline,
        :hero_copy,
        :map_link,
        hero_images: Temple::HERO_TABS,
        contact: %i[phone],
        service_times: {},
        visit_info: %i[transportation parking],
        about: [
          :hero_subtitle,
          { cards: {
            history: [:body],
            deities: [:body],
            etiquette: [:body]
          } }
        ]
      )
    end

    def ensure_temple!
      return if current_temple.present?

      redirect_to admin_dashboard_path, alert: t("admin.temple_profile.flash.not_found")
    end
  end
end
