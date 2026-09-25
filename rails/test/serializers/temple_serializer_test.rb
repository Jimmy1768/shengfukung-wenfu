require "test_helper"

# The public API must not carry text addressed to an admin.
#
# TempleSerializer used to return AppConstants::TempleProfilePlaceholders for a
# temple that had written nothing, so /api/v1/temple answered with
# "尚未設定地址（請至後台「Temple Profile」更新）" -- an instruction to update the
# backend, served to whoever asked. The public site then rendered it. Observed
# 2026-09-25 in the live footer.
#
# The forbidden strings are literals here rather than read from the placeholder
# JSON, because they have been deleted from it. This list is the record of what
# must never reach a visitor; it does not depend on the file that once held them.
class TempleSerializerTest < ActiveSupport::TestCase
  ADMIN_FACING_STRINGS = [
    "尚未設定地址（請至後台「Temple Profile」更新）",
    "Address pending — update Temple Profile to publish directions.",
    "尚未設定電話",
    "Plus Code 尚未設定",
    "尚未設定（請更新開放時間）",
    "提示：在 Temple Profile → Service schedule 填寫詳細說明。",
    "尚未設定交通資訊（請在 Temple Profile → Visit info 填寫）。",
    "尚未設定停車/提醒資訊（請在 Temple Profile → Visit info 填寫）。",
    "例如：創建年代、地方故事、重要里程碑。",
    "例如：主神、陪祀神祇、簡短介紹與參拜重點。",
    "例如：入廟動線、禁忌提醒、拍照注意事項。"
  ].freeze

  # Broader than the list above, so a newly invented instruction is caught too.
  ADMIN_FACING_MARKERS = ["尚未設定", "例如：", "Temple Profile", "（Placeholder）", "(Placeholder)"].freeze

  # A temple that has filled nothing in -- the case the placeholders existed for.
  # contact_details reads the contact_info column, service_schedule reads
  # service_times, and visit_info and about_content read keys out of metadata.
  def bare_temple
    create_temple(contact_info: {}, service_times: {}, metadata: {})
  end

  test "a temple with no profile data serves none of the admin-facing strings" do
    payload = TempleSerializer.new(bare_temple).as_json.to_json

    offenders = ADMIN_FACING_STRINGS.select { |text| payload.include?(text) }

    assert_empty offenders,
      "the public API returned text addressed to an admin: #{offenders.first(3).inspect}. " \
      "A visitor cannot act on an instruction to update the backend, and this payload " \
      "is what the public site renders."
  end

  test "a temple with no profile data serves no admin-facing marker at all" do
    payload = TempleSerializer.new(bare_temple).as_json.to_json

    offenders = ADMIN_FACING_MARKERS.select { |marker| payload.include?(marker) }

    assert_empty offenders,
      "the public API returned #{offenders.inspect}, which marks text written for an " \
      "admin or as an example rather than for a visitor."
  end

  # Empty rather than nil, so a consumer reading contact.phone gets nothing back
  # instead of raising -- the same shape it already handled for a blank field.
  test "the four profile sections come back empty rather than invented" do
    payload = TempleSerializer.new(bare_temple).as_json

    assert_empty payload[:contact]
    assert_empty payload[:service_times]
    assert_empty payload[:visit_info]
    assert_empty payload[:about]
  end

  # The guard must not pass by serializing nothing: real data still has to arrive.
  test "a temple that has filled its details in still serves them" do
    temple = create_temple(
      contact_info: { "addressZh" => "苗栗縣造橋鄉", "phone" => "037-622454" },
      service_times: { "weekday" => "06:00-18:00" },
      metadata: {
        "visit_info" => { "parking" => "廟前廣場" },
        "about" => { "cards" => [{ "title" => "沿革", "body" => "創建於1900年" }] }
      }
    )

    payload = TempleSerializer.new(temple).as_json

    assert_equal "037-622454", payload[:contact]["phone"]
    assert_equal "06:00-18:00", payload[:service_times]["weekday"]
    assert_equal "廟前廣場", payload[:visit_info]["parking"]
    assert_equal "創建於1900年", payload[:about]["cards"].first["body"]
  end
end
