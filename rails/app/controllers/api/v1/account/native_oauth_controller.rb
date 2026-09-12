# frozen_string_literal: true

module Api
  module V1
    module Account
      class NativeOAuthController < NativeBaseController
        skip_before_action :authenticate_native_user!, only: %i[start exchange]

        def start
          payload = flow.start!(**start_params)
          render json: payload, status: :created
        rescue Auth::NativeOAuthTransaction::UnsupportedProvider
          render_error("unsupported_oauth_provider", :unprocessable_entity)
        rescue Auth::NativeOAuthTransaction::InvalidPkce
          render_error("invalid_pkce", :unprocessable_entity)
        rescue Auth::NativeOAuthTransaction::InvalidTransaction
          render_error("invalid_oauth_transaction", :unprocessable_entity)
        rescue Auth::NativeOAuthFlow::ConfigurationError
          render_error("native_oauth_unavailable", :service_unavailable)
        rescue Auth::NativeOAuthFlow::UpstreamError
          render_error("oauth_start_failed", :bad_gateway)
        end

        def exchange
          result = flow.exchange!(**exchange_params)
          if result.account_resolution.present?
            return render json: {
              code: "account_resolution_required",
              # The name and email Google/Apple already gave us, so the
              # resolution form can prefill instead of making the patron
              # retype what we were handed. Hints only -- consume_new! reads
              # whatever is actually submitted, and the patron can edit both.
              # Discloses nothing new: it is the identity they just signed in
              # with, returned to the client that completed the exchange.
              oauth: {
                provider: result.provider,
                resolution_token: result.account_resolution.token,
                name: result.account_resolution.record&.display_name,
                email: result.account_resolution.record&.email
              }
            }, status: :conflict
          end

          render json: {
            user: ::Account::Api::NativeAccountSerializer.user(result.user),
            session: issue_session_payload(result.user, context: native_context),
            oauth: { provider: result.provider, profile_required: result.profile_required }
          }
        rescue Auth::NativeOAuthTransaction::ExpiredTransaction
          render_error("oauth_transaction_expired", :unauthorized)
        rescue Auth::NativeOAuthTransaction::InvalidPkce
          render_error("invalid_pkce", :unprocessable_entity)
        rescue Auth::NativeOAuthTransaction::InvalidTransaction
          render_error("invalid_oauth_transaction", :unauthorized)
        rescue Auth::NativeOAuthFlow::ConfigurationError
          render_error("native_oauth_unavailable", :service_unavailable)
        rescue Auth::NativeOAuthFlow::ProviderMismatch
          render_error("oauth_provider_mismatch", :unprocessable_entity)
        rescue Auth::NativeOAuthFlow::ClosedAccount
          render_error("account_closed", :unauthorized)
        rescue Auth::NativeOAuthFlow::IdentityError
          render_error("oauth_identity_invalid", :unprocessable_entity)
        rescue Auth::NativeOAuthFlow::ResolutionUnavailable
          render_error("account_resolution_unavailable", :service_unavailable)
        rescue Auth::NativeOAuthFlow::InvalidGrant
          render_error("invalid_oauth_grant", :unprocessable_entity)
        rescue Auth::NativeOAuthFlow::UpstreamError
          render_error("oauth_exchange_failed", :bad_gateway)
        end

        private

        def flow
          @flow ||= Auth::NativeOAuthFlow.new
        end

        def start_params
          oauth = params.fetch(:oauth, {}).permit(:provider, :pkce_challenge, :pkce_method)
          {
            provider: oauth[:provider].to_s,
            pkce_challenge: oauth[:pkce_challenge].to_s,
            pkce_method: oauth[:pkce_method].to_s
          }
        end

        def exchange_params
          oauth = params.fetch(:oauth, {}).permit(:code, :transaction_token, :pkce_verifier)
          {
            code: oauth[:code].to_s,
            transaction_token: oauth[:transaction_token].to_s,
            pkce_verifier: oauth[:pkce_verifier].to_s
          }
        end
      end
    end
  end
end
