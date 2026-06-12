require "test_helper"

class AdminGatheringsLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(
      temple: @temple,
      role: "admin",
      permission_overrides: { manage_offerings: true }
    )
    sign_in_admin(@admin)
  end

  test "new gathering form renders as fluid two-column stage" do
    get new_admin_gathering_path

    assert_response :success
    assert_includes response.body, 'class="form-stack stack-item stack-item--fluid gathering-form"'
    assert_includes response.body, 'class="offering-form-stage gathering-form-stage"'
    assert_includes response.body, 'class="offering-form-stage__primary"'
    assert_includes response.body, 'class="offering-form-stage__secondary-list"'
    assert_select "input[name='temple_gathering[title]']"
    assert_select "input[name='temple_gathering[price_cents]']"
    assert_select "input[name='temple_gathering[hero_asset_id]']"
    assert_select "textarea[name='temple_gathering[location_notes]']"
  end

  test "gathering form still submits existing params" do
    assert_difference -> { @temple.temple_gatherings.count }, 1 do
      post admin_gatherings_path, params: {
        temple_gathering: {
          title: "Community Tea",
          subtitle: "Monthly meetup",
          description: "A simple gathering for temple members.",
          free_gathering: "0",
          price_cents: "200",
          currency: "TWD",
          starts_on: Date.current,
          ends_on: Date.current,
          start_time: "09:00",
          end_time: "10:00",
          location_name: "Main Hall",
          location_address: "1 Temple Road",
          location_notes: "Enter through the side gate.",
          status: "draft",
          hero_image_url: "https://example.test/gathering.jpg"
        }
      }
    end

    assert_redirected_to admin_gatherings_path
    gathering = @temple.temple_gatherings.find_by!(title: "Community Tea")
    assert_equal "Monthly meetup", gathering.subtitle
    assert_equal 20_000, gathering.price_cents
    assert_equal "TWD", gathering.currency
    assert_equal "Main Hall", gathering.location_name
    assert_equal "draft", gathering.status
  end
end
