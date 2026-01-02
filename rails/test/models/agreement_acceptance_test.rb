require "test_helper"

class AgreementAcceptanceTest < ActiveSupport::TestCase
  setup do
    @agreement = Agreement.create!(
      key: "test.terms",
      version: 1,
      title: "Test Terms",
      body: "Body",
      effective_on: Date.current
    )
    @user = User.create!(
      email: "agreement-acceptance@test.local",
      english_name: "Agreement User",
      encrypted_password: User.password_hash("TestPassword!23")
    )
  end

  test "requires accepted_at and body_snapshot" do
    acceptance = AgreementAcceptance.new(agreement: @agreement, user: @user)
    assert_not acceptance.valid?
    assert_includes acceptance.errors[:accepted_at], "can't be blank"
    assert_includes acceptance.errors[:body_snapshot], "can't be blank"
  end
end
