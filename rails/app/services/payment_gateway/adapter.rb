# frozen_string_literal: true

module PaymentGateway
  class Adapter
    def verify_webhook_signature(**)
      raise NotImplementedError, "#{self.class.name} must implement #verify_webhook_signature"
    end

    def checkout(**)
      raise NotImplementedError, "#{self.class.name} must implement #checkout"
    end

    def ingest_webhook(**)
      raise NotImplementedError, "#{self.class.name} must implement #ingest_webhook"
    end

    def confirm(**)
      raise NotImplementedError, "#{self.class.name} must implement #confirm"
    end

    def query_status(**)
      raise NotImplementedError, "#{self.class.name} must implement #query_status"
    end

    def refund(**)
      raise NotImplementedError, "#{self.class.name} must implement #refund"
    end

    def cancel(**)
      raise NotImplementedError, "#{self.class.name} must implement #cancel"
    end
  end
end
