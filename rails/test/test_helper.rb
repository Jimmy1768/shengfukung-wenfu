ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Creates the test database when it is missing, so the suite provisions itself.
#
# Why. The Director's database policy makes a test database disposable: created
# for an implementation, deleted when it ends, with development as the sandbox
# for dummy data. The scaffolding contradicted that. `rails/test_help` maintains
# a schema but does not create a database, so an absent one raised
# ActiveRecord::NoDatabaseError and the suite aborted before running a test,
# telling the operator to go run `bin/rails db:create`. A policy that says
# "delete it when you are done" and tooling that punishes you for having done so
# pull against each other, and the tooling wins, so databases outlive their
# tasks. Observed 2026-09-13: this database vanished mid-session and the time
# went on deciding whether it was a defect, a concurrent run or a real change.
#
# It is deliberately a module taking injectable collaborators. The alternative
# is a begin/rescue inline here, which can only be exercised by actually
# destroying a database, so the cases that matter -- that it does nothing
# outside test, that it drops nothing -- would never be tested at all.
module TestDatabaseProvisioner
  module_function

  # Creates the test database when it is missing, and removes it again when the
  # run that created it ends. Returns :created, :present, or :skipped_not_test.
  #
  # THE BOUND IS THE WHOLE DESIGN: a run removes only what that run created. A
  # database that was already there is used and left alone. That is what makes
  # this safe without knowing anything about how databases are named or how
  # checkouts are laid out -- a teardown can never land on another checkout's
  # running suite, whatever the two are called. An earlier attempt built a
  # per-checkout naming scheme to satisfy a precondition that was never real;
  # naming is a separate decision and is a precondition for nothing here.
  #
  # Concretely, the only way removal is ever armed is the `arm` call in the
  # rescue below, which is reached only after this run has itself created the
  # database, and it is handed the config captured at that moment. There is no
  # call path that arms removal for a database this run found.
  #
  # env       - the environment name; provisioning happens in "test" and nowhere else
  # out       - where the one announcement line goes
  # tasks     - the ActiveRecord database task interface
  # connect   - callable that touches the database and raises NoDatabaseError if absent
  # reconnect - callable run after creation, so later code gets a live connection
  # arm       - callable given the config of a database this run created, which
  #             arranges for it to be removed when the run ends
  def provision!(
    env: Rails.env,
    out: $stdout,
    tasks: ActiveRecord::Tasks::DatabaseTasks,
    connect: -> { ActiveRecord::Base.connection.execute("SELECT 1") },
    reconnect: -> { ActiveRecord::Base.establish_connection(:test) },
    arm: method(:arm_removal)
  )
    # The guard is first and unconditional. Creating or removing a database is
    # not something this file may do in development, staging or production under
    # any circumstance, including being loaded by accident.
    return :skipped_not_test unless env.to_s == "test"

    begin
      connect.call
      # Found, not made. Used as-is, left alone, and nothing is armed -- this is
      # the branch that makes the bound true.
      :present
    rescue ActiveRecord::NoDatabaseError
      config = ActiveRecord::Base.connection_db_config

      out.puts(
        "[test] #{config.database} does not exist; creating it and loading " \
          "db/schema.rb. This run made it, so this run removes it when it ends."
      )

      tasks.create(config)
      tasks.load_schema(config)
      reconnect.call
      arm.call(config)
      :created
    end
  end

  # Removes a database this run created. Returns :removed, :skipped_not_test, or
  # :failed.
  #
  # Never call this with a config you did not just create. It is deliberately
  # not named `drop_test_database` and takes no name: the only supported caller
  # is arm_removal, holding a config from the rescue branch above.
  def remove!(
    config:,
    env: Rails.env,
    out: $stdout,
    tasks: ActiveRecord::Tasks::DatabaseTasks,
    disconnect: -> { ActiveRecord::Base.connection_handler.clear_all_connections! }
  )
    return :skipped_not_test unless env.to_s == "test"

    disconnect.call
    tasks.drop(config)
    # Same register as the create line, and one line: the pair should read as
    # one obligation rather than two events.
    out.puts("[test] removed #{config.database}, which this run created.")
    :removed
  rescue StandardError => error
    # A teardown failure must not turn a green suite red -- the run's result is
    # about the code under test, not about cleanup. But it must not be quiet
    # either, so this names the database precisely enough to remove by hand.
    out.puts(
      "[test] could not remove #{config.database} (#{error.class}: #{error.message}). " \
        "It was created by this run and is now a stray: remove it with " \
        "`dropdb #{config.database}`."
    )
    :failed
  end

  # at_exit rather than Minitest.after_run, because a run that fails or errors
  # still has to remove what it made -- a stray is not the price of a red suite,
  # and at_exit also covers an exception raised while test files are loading,
  # which never reaches Minitest at all. A hard kill still leaves the database;
  # nothing in-process can cover that, and the next run will find it and, by the
  # bound above, leave it alone rather than removing someone else's.
  def arm_removal(config)
    at_exit { remove!(config: config) }
  end
end

TestDatabaseProvisioner.provision!

require "rails/test_help"
require "minitest/mock"
require "securerandom"
module TestDataHelpers
  def create_temple(attrs = {})
    Temple.create!(
      { slug: "temple-#{SecureRandom.hex(2)}", name: "Test Temple" }.merge(attrs)
    )
  end

  def create_admin_user(
    temple: create_temple,
    create_permission: true,
    password: "Password123!",
    role: "owner",
    membership_role: nil,
    permission_overrides: {}
  )
    user = User.create!(
      email: "admin-#{SecureRandom.hex(2)}@example.com",
      encrypted_password: User.password_hash(password),
      english_name: "Admin User"
    )
    admin_account = AdminAccount.create!(
      user:,
      active: true,
      role: role.to_s
    )
    AdminTempleMembership.create!(
      admin_account:,
      temple:,
      role: (membership_role || role).to_s
    )
    if create_permission
      AdminPermission.create!(
        { admin_account:, temple:, manage_permissions: role.to_s == "owner" }
          .merge(permission_overrides)
      )
    end
    user
  end

  def create_offering(temple: create_temple, price_cents: 1_000, currency: "TWD", **attrs)
    temple.temple_offerings.create!(
      {
        slug: "offering-#{SecureRandom.hex(2)}",
        title: "Test Offering",
        offering_type: "general",
        starts_on: Date.current,
        ends_on: Date.current + 1.day,
        price_cents:,
        currency:
      }.merge(attrs)
    )
  end

  # Binding is the join: a signed-in patron who scans the temple's QR or
  # selects it on the web is on its list from that moment, having bought
  # nothing. Use this to make a fixture user visible to that temple's admin
  # surfaces, the same way the app would.
  def join_temple!(user, temple)
    TempleConnection.record!(user:, temple:)
  end

  def create_registration(user:, offering:, **attrs)
    TempleEventRegistration.create!(
      {
        temple: offering.temple,
        registrable: offering,
        user:,
        reference_code: "REG-#{SecureRandom.hex(2).upcase}",
        quantity: 1,
        unit_price_cents: offering.price_cents,
        total_price_cents: offering.price_cents,
        currency: offering.currency,
        payment_status: "pending",
        fulfillment_status: "open",
        contact_payload: { "name" => user.english_name, "email" => user.email },
        # Defaults to already admin-completed so existing callers testing
        # something else aren't tripped up by the semi-automatic
        # registration checkpoint (see TempleRegistration#checkout_ready?).
        # Pass admin_completed_at: nil explicitly to test that gate itself.
        admin_completed_at: Time.current
      }.merge(attrs)
    )
  end

  def create_payment(registration:, amount_cents: registration.total_price_cents, status: TemplePayment::STATUSES[:completed], method: TemplePayment::PAYMENT_METHODS[:cash], **attrs)
    defaults = {
      temple: registration.temple,
      temple_event_registration: registration,
      user: registration.user,
      amount_cents:,
      currency: registration.currency,
      payment_method: method,
      status:,
      processed_at: Time.current,
      provider: "demo",
      provider_account: "temple",
      payment_payload: {},
      metadata: {}
    }
    TemplePayment.create!(defaults.merge(attrs))
  end
end

class ActiveSupport::TestCase
  self.use_transactional_tests = true
  include TestDataHelpers

  def assert_valid(record, message = nil)
    message ||= "Expected #{record.inspect} to be valid"
    assert record.valid?, message
  end
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers
  include TestDataHelpers

  def sign_in_admin(user, password: "Password123!")
    post admin_sessions_path, params: { session: { email: user.email, password: } }
    follow_redirect! if response.redirect?
  end

  def sign_in_account(user, password: "Password123!", temple_slug: nil)
    request_params = {}
    request_params[:temple_slug] = temple_slug if temple_slug.present?
    request_params[:session] = { email: user.email, password: }
    post account_sessions_path, params: request_params
    follow_redirect! if response.redirect?
  end
end
