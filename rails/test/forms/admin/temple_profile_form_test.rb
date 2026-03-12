require "test_helper"

class Admin::TempleProfileFormTest < ActiveSupport::TestCase
  test "about cards round trip through stored titled array entries" do
    temple = create_temple(
      metadata: {
        "about" => {
          "hero_subtitle" => "test 1",
          "cards" => [
            { "title" => "沿革", "body" => "test 2" },
            { "title" => "主祀 / 配祀", "body" => "test 3" },
            { "title" => "參拜禮儀", "body" => "test 4" }
          ]
        }
      }
    )

    form = Admin::TempleProfileForm.new(temple: temple)

    cards = form.about_card_definitions.index_by { |entry| entry[:key] }

    assert_equal "test 1", form.about[:hero_subtitle]
    assert_equal "test 2", cards.fetch("history")[:body]
    assert_equal "test 3", cards.fetch("deities")[:body]
    assert_equal "test 4", cards.fetch("etiquette")[:body]
  end

  test "profile form round trips persisted page fields" do
    temple = create_temple(slug: "shengfukung-wenfu", name: "Old Temple")
    admin = create_admin_user(temple: temple, role: "owner")

    form = Admin::TempleProfileForm.new(
      temple: temple,
      params: {
        name: "竹南鎮聖福宮",
        tagline: "tagline",
        hero_copy: "hero copy",
        contact: { phone: "02-1234-5678" },
        service_times: {
          weekday: "08:00-17:00",
          weekend: "08:00-18:00",
          notes: "service notes"
        },
        visit_info: {
          transportation: "transport info",
          parking: "parking info"
        },
        hero_images: {
          "home" => "https://example.com/home.jpg",
          "about" => "https://example.com/about.jpg",
          "events" => "",
          "event" => "",
          "archive" => "",
          "news" => "",
          "services" => "",
          "contact" => ""
        },
        about: {
          hero_subtitle: "test 1",
          cards: {
            history: { body: "test 2" },
            deities: { body: "test 3" },
            etiquette: { body: "test 4" }
          }
        }
      }
    )

    assert form.save(current_admin: admin)

    temple.reload
    reloaded_form = Admin::TempleProfileForm.new(temple: temple)
    cards = reloaded_form.about_card_definitions.index_by { |entry| entry[:key] }

    assert_equal "竹南鎮聖福宮", temple.name
    assert_equal "tagline", temple.tagline
    assert_equal "hero copy", temple.hero_copy
    assert_equal "02-1234-5678", temple.contact_details["phone"]
    assert_equal "08:00-17:00", temple.service_schedule["weekday"]
    assert_equal "08:00-18:00", temple.service_schedule["weekend"]
    assert_equal "service notes", temple.service_schedule["notes"]
    assert_equal "transport info", temple.visit_info["transportation"]
    assert_equal "parking info", temple.visit_info["parking"]
    assert_equal "https://example.com/home.jpg", temple.hero_images["home"]
    assert_equal "https://example.com/about.jpg", temple.hero_images["about"]
    assert_equal "test 1", reloaded_form.about[:hero_subtitle]
    assert_equal "test 2", cards.fetch("history")[:body]
    assert_equal "test 3", cards.fetch("deities")[:body]
    assert_equal "test 4", cards.fetch("etiquette")[:body]
  end
end
