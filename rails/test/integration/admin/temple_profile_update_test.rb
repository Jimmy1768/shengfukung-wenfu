# frozen_string_literal: true

require "test_helper"

class Admin::TempleProfileUpdateTest < ActionDispatch::IntegrationTest
  test "profile update resolves current temple when temple params are form attributes" do
    temple = create_temple(name: "Old Temple", slug: "shengfukung-wenfu")
    owner = create_admin_user(
      temple: temple,
      role: "owner",
      permission_overrides: { manage_profile: true }
    )

    sign_in_admin(owner)

    assert_difference -> { SystemAuditLog.where(action: "admin.temple_profile.updated").count }, 1 do
      patch admin_temple_profile_path, params: {
        temple: {
          name: "竹南鎮聖福宮",
          tagline: "信仰、公益、環保、科技",
          hero_copy: "",
          about: {
            hero_subtitle: "",
            cards: {
              history: { body: "聖福宮興建經過" },
              deities: { body: "" },
              etiquette: { body: "" }
            }
          },
          contact: { phone: "037-472826" },
          map_link: "",
          service_times: {
            weekday: "06:00-20:00",
            weekend: "06:00-20:00",
            notes: "農曆初一、十五延長開放"
          },
          visit_info: {
            transportation: "竹南火車站可騎 Ubike 至聖福公園站",
            parking: "廟前廣場有停車格"
          },
          hero_images: {
            home: "https://example.com/home.jpg",
            about: "",
            events: "",
            event: "",
            archive: "",
            news: "",
            services: "",
            contact: ""
          }
        },
        temple_profile_save_scope: "hero_images"
      }
    end

    assert_redirected_to admin_temple_profile_path
    temple.reload
    assert_equal "竹南鎮聖福宮", temple.name
    assert_equal "https://example.com/home.jpg", temple.hero_images["home"]
  end

  test "profile update uploads selected hero image files during save" do
    temple = create_temple(name: "Old Temple", slug: "shengfukung-wenfu")
    owner = create_admin_user(
      temple: temple,
      role: "owner",
      permission_overrides: { manage_profile: true }
    )
    uploaded_url = "https://cdn.example.test/hero-home.jpg"
    uploaded_tabs = []

    sign_in_admin(owner)

    uploader = lambda do |temple:, file:, hero_tab:, admin:|
      uploaded_tabs << hero_tab
      asset = temple.media_assets.create!(
        role: :hero_image,
        file_uid: "test/#{hero_tab}.jpg",
        metadata: {
          "hero_tab" => hero_tab.to_s,
          "url" => uploaded_url,
          "filename" => file.original_filename,
          "admin_id" => admin.id
        }
      )
      { url: uploaded_url, asset: asset }
    end

    MediaAssets::HeroImageUploader.stub(:call, uploader) do
      patch admin_temple_profile_path, params: {
        temple: {
          name: "竹南鎮聖福宮",
          tagline: "信仰、公益、環保、科技",
          hero_copy: "",
          contact: { phone: "037-472826" },
          map_link: "",
          service_times: {
            weekday: "06:00-20:00",
            weekend: "06:00-20:00",
            notes: ""
          },
          visit_info: {
            transportation: "",
            parking: ""
          },
          about: {
            hero_subtitle: "",
            cards: {
              history: { body: "" },
              deities: { body: "" },
              etiquette: { body: "" }
            }
          },
          hero_images: {
            home: "",
            about: "",
            events: "",
            event: "",
            archive: "",
            news: "",
            services: "",
            contact: ""
          }
        },
        hero_image_upload: {
          home: Rack::Test::UploadedFile.new(
            Rails.root.join("public/backend/assets/admin/hero-placeholder.svg"),
            "image/svg+xml"
          )
        },
        temple_profile_save_scope: "hero_images"
      }
    end

    assert_redirected_to admin_temple_profile_path
    assert_equal ["home"], uploaded_tabs
    assert_equal uploaded_url, temple.reload.hero_images["home"]
  end
end
