require "test_helper"

class ApiTimeEntriesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    @headers = { "Authorization" => "Token token=#{@user.api_token}" }
    time_entries(:regular_run).update!(location: "Cluj-Napoca")
    @user.time_entries.create!(date: "2026-11-03", distance_km: 4, duration_seconds: 1200, location: "Oradea")
    @user.time_entries.create!(date: "2026-11-04", distance_km: 3, duration_seconds: 900, location: "100% Park")
  end

  def locations(filter)
    get api_time_entries_path, params: { location: filter }, headers: @headers
    assert_response :success
    response.parsed_body.map { |entry| entry["location"] }
  end

  test "filters entries by part of the location" do
    assert_equal ["Cluj-Napoca"], locations("cluj")
  end

  test "treats wildcard characters in the location filter as text" do
    assert_equal ["100% Park"], locations("%")
  end
end
