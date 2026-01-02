require "test_helper"

class AgreementTest < ActiveSupport::TestCase
  test "requires key, version, title, body, and effective date" do
    agreement = Agreement.new
    agreement.version = nil
    agreement.validate
    %i[key version title body effective_on].each do |field|
      assert agreement.errors.added?(field, :blank), "Expected #{field} to be blank"
    end
  end
end
