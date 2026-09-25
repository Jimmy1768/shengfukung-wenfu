# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/seeds/temples")

# On 2026-09-01 a routine `rails db:seed` on production -- run to apply a
# temple rename -- wiped the demo temple's uploaded hero images back to
# DEFAULT_HERO_IMAGE, because the seed assigned every profile field
# unconditionally from a yml that leaves them blank. Every field it touches is
# also editable in the admin console (Admin::TempleProfileForm).
class TempleSeedPreservesAdminContentTest < ActiveSupport::TestCase
  test "re-seeding applies the yml but never blanks admin-owned content" do
    temple = Temple.find_by(slug: "shengfukung-demo") ||
             Temple.create!(slug: "shengfukung-demo", name: "placeholder")

    temple.update!(
      name: "STALE NAME",
      hero_images: { "home" => "https://cdn.example/uploaded-hero.jpg" },
      primary_image_url: "https://cdn.example/uploaded-primary.jpg",
      about_html: "<p>admin wrote this</p>"
    )

    Seeds::Temples.seed
    temple.reload

    # The yml supplies a name, so a rename still lands.
    assert_equal "示範宮廟", temple.name

    # It supplies none of these, so the admin's work survives.
    assert_equal({ "home" => "https://cdn.example/uploaded-hero.jpg" }, temple.hero_images)
    assert_equal "https://cdn.example/uploaded-primary.jpg", temple.primary_image_url
    assert_equal "<p>admin wrote this</p>", temple.about_html
  end

  test "a brand new temple stores no hero images and resolves them to the floor" do
    fresh = Temple.new(slug: "seed-fresh-temple", name: "Fresh")

    images = Seeds::Temples.send(:hero_images_for, fresh, {})

    assert_empty images,
      "the seed must persist only what the yml supplies -- the floor is applied at render time"
    Temple::HERO_TABS.each do |tab|
      assert_equal Temple::DEFAULT_HERO_IMAGE, fresh.hero_image_for(tab),
        "#{tab} must still resolve to the placeholder without it being stored"
    end
  end

  test "the seed keeps what the yml supplies and drops the rest" do
    fresh = Temple.new(slug: "seed-fresh-temple", name: "Fresh")

    images = Seeds::Temples.send(:hero_images_for, fresh,
                                 { "hero_images" => { "home" => "https://cdn.example/from-yml.jpg", "about" => "" } })

    assert_equal({ "home" => "https://cdn.example/from-yml.jpg" }, images)
  end
end
