# frozen_string_literal: true

require "test_helper"

class NativeOAuthTransactionTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @return_url = "templemate://oauth/complete"
    @verifier = "v" * 43
    @challenge = Auth::NativeOAuthTransaction.s256_challenge(@verifier)
  end

  test "issues an opaque signed five minute transaction bound to its inputs" do
    token = issue
    assert_not_includes token, @challenge

    payload = verify(token)
    # No temple. Signing in is not temple-scoped, so there is nothing about a
    # temple for this token to carry or to be checked against.
    assert_not payload.key?("temple_slug")
    assert_equal "google", payload.fetch("provider")
    assert_equal "S256", payload.fetch("pkce_method")
    assert_equal 1, payload.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, payload.fetch("nonce"))
  end

  test "rejects tamper expiry provider return URL and verifier mismatch" do
    token = issue
    assert_raises(Auth::NativeOAuthTransaction::InvalidTransaction) { verify("#{token}x") }
    assert_raises(Auth::NativeOAuthTransaction::InvalidTransaction) { Auth::NativeOAuthTransaction.verify!(token:, return_url: @return_url, provider: "apple", pkce_verifier: @verifier) }
    assert_raises(Auth::NativeOAuthTransaction::InvalidTransaction) { Auth::NativeOAuthTransaction.verify!(token:, return_url: "templemate://changed", pkce_verifier: @verifier) }
    assert_raises(Auth::NativeOAuthTransaction::InvalidTransaction) { Auth::NativeOAuthTransaction.verify!(token:, return_url: @return_url, pkce_verifier: "x" * 43) }

    travel Auth::NativeOAuthTransaction::TTL + 1.second do
      assert_raises(Auth::NativeOAuthTransaction::ExpiredTransaction) { verify(token) }
    end
  end

  test "requires supported providers and valid S256 input" do
    assert_raises(Auth::NativeOAuthTransaction::UnsupportedProvider) { issue(provider: "facebook") }
    assert_raises(Auth::NativeOAuthTransaction::InvalidPkce) { issue(pkce_method: "plain") }
    assert_raises(Auth::NativeOAuthTransaction::InvalidPkce) { issue(pkce_challenge: "short") }
    assert_raises(Auth::NativeOAuthTransaction::InvalidPkce) { Auth::NativeOAuthTransaction.verify!(token: issue, return_url: @return_url, pkce_verifier: "short") }
  end

  private

  def issue(provider: "google", pkce_challenge: @challenge, pkce_method: "S256")
    Auth::NativeOAuthTransaction.issue!(provider:, return_url: @return_url, pkce_challenge:, pkce_method:)
  end

  def verify(token)
    Auth::NativeOAuthTransaction.verify!(token:, return_url: @return_url, pkce_verifier: @verifier)
  end
end
