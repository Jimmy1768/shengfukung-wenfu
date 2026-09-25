# frozen_string_literal: true

require "test_helper"

# The admin console promises "未填寫的頁面會使用「首頁」圖片" -- unfilled tabs
# inherit the home image. That was false wherever a seeded placehold.co media
# asset sat in front of the fallback, because the media-asset branch returned
# its URL unsanitized while the map branch filtered placeholders.
class TempleHeroImageFallbackTest < ActiveSupport::TestCase
  setup do
    @temple = Temple.find_by(slug: "shengfukung-demo") ||
              Temple.create!(slug: "shengfukung-demo", name: "示範宮廟")
  end

  test "every tab inherits the home image when only home is uploaded" do
    @temple.update!(hero_images: { "home" => "https://cdn.example/home.jpg" })

    Temple::HERO_TABS.each do |tab|
      assert_equal "https://cdn.example/home.jpg", @temple.hero_image_for(tab),
        "#{tab} should inherit the home image"
    end
  end

  test "a tab with its own image keeps it" do
    @temple.update!(hero_images: {
      "home" => "https://cdn.example/home.jpg",
      "archive" => "https://cdn.example/archive.jpg"
    })

    assert_equal "https://cdn.example/archive.jpg", @temple.hero_image_for("archive")
    assert_equal "https://cdn.example/home.jpg", @temple.hero_image_for("news")
  end

  test "the seven page heroes match the public site navigation, in order" do
    # vue/src/components/site/SiteHeader.vue navItems.
    assert_equal %w[home about news services events archive contact], Temple::PAGE_HERO_TABS
  end

  test "the event fallback is a valid storage key but not a page hero" do
    # It must stay in HERO_TABS -- param slicing, upload validation and the
    # seed normalizer all gate on that list -- while being presented on its
    # own in the admin rather than as an eighth page tile.
    refute_includes Temple::PAGE_HERO_TABS, Temple::EVENT_FALLBACK_TAB
    assert_includes Temple::HERO_TABS, Temple::EVENT_FALLBACK_TAB
    assert_equal Temple::PAGE_HERO_TABS.size + 1, Temple::HERO_TABS.size
  end
end
