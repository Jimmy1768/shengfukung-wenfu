# frozen_string_literal: true

module Payments
  class LinePayGatewayStub
    Result = Struct.new(:success?, :transaction_id, :payload, keyword_init: true)

    def create_order(**)
      Result.new(success?: true, transaction_id: SecureRandom.uuid, payload: { stubbed: true })
    end

    def confirm_order(**)
      Result.new(success?: true, transaction_id: SecureRandom.uuid, payload: { confirmed: true })
    end
  end
end
