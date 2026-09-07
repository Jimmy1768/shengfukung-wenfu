require "test_helper"

# Guards the regression these names were changed to fix: the template hardcoded
# DEFAULT_DB_BASE = "golden_template" and DEFAULT_BUCKET_PREFIX = "golden-template",
# so every project cloned from it fell back to the same Postgres databases and the
# same S3 buckets. A sibling clone running its test suite wrote into this project's
# test database.
class ProfileInfrastructureStorageTest < ActiveSupport::TestCase
  Storage = Profile::Infrastructure::Storage

  test "database base derives from the project slug" do
    AppConstants::Project.stub(:slug, "acme-clinic") do
      assert_equal "acme_clinic", Storage.db_base
    end
  end

  test "bucket prefix derives from the project slug" do
    AppConstants::Project.stub(:slug, "acme-clinic") do
      assert_equal "acme-clinic", Storage.bucket_prefix
    end
  end

  test "two different slugs never resolve to the same database" do
    a = AppConstants::Project.stub(:slug, "acme-clinic") { Storage.db_name(env: :test) }
    b = AppConstants::Project.stub(:slug, "shengfukung-wenfu") { Storage.db_name(env: :test) }

    assert_equal "acme_clinic_test", a
    assert_equal "shengfukung_wenfu_test", b
    refute_equal a, b
  end

  test "two different slugs never resolve to the same bucket" do
    a = AppConstants::Project.stub(:slug, "acme-clinic") { Storage.s3_bucket(env: :production) }
    b = AppConstants::Project.stub(:slug, "shengfukung-wenfu") { Storage.s3_bucket(env: :production) }

    refute_equal a, b
  end

  test "names are suffixed per environment" do
    AppConstants::Project.stub(:slug, "acme-clinic") do
      assert_equal "acme_clinic",         Storage.db_name(env: :production)
      assert_equal "acme_clinic_dev",     Storage.db_name(env: :development)
      assert_equal "acme_clinic_test",    Storage.db_name(env: :test)
      assert_equal "acme_clinic_staging", Storage.db_name(env: :staging)

      assert_equal "acme-clinic",       Storage.s3_bucket(env: :production)
      assert_equal "acme-clinic-dev",   Storage.s3_bucket(env: :development)
      assert_equal "acme-clinic-test",  Storage.s3_bucket(env: :test)
    end
  end

  test "slugs with spaces punctuation or casing normalise safely" do
    AppConstants::Project.stub(:slug, "  Acme Clinic (TW)!  ") do
      assert_equal "acme_clinic_tw", Storage.db_base
      assert_equal "acme-clinic-tw", Storage.bucket_prefix
    end
  end

  test "a slug with no usable characters falls back rather than producing an empty name" do
    AppConstants::Project.stub(:slug, "---") do
      assert_equal "app", Storage.db_base
      assert_equal "app", Storage.bucket_prefix
    end
  end

  test "environment variables still override the derived names" do
    with_env("POSTGRES_TEST_DB" => "explicit_db", "S3_BUCKET_TEST" => "explicit-bucket") do
      AppConstants::Project.stub(:slug, "acme-clinic") do
        assert_equal "explicit_db",     Storage.db_name(env: :test)
        assert_equal "explicit-bucket", Storage.s3_bucket(env: :test)
      end
    end
  end

  private

  def with_env(vars)
    previous = vars.keys.index_with { |key| ENV[key] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
