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
end
