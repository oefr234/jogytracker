require "test_helper"

class ApiAuthorizationTest < ActionDispatch::IntegrationTest
  def auth(user)
    { "Authorization" => "Token token=#{user.api_token}" }
  end

  def regular = users(:regular)
  def other = users(:other_regular)
  def manager = users(:manager)
  def admin = users(:admin)

  def new_user_params(role)
    { user: { name: "New", email: "new@example.com", password: "secret1", password_confirmation: "secret1", role: role } }
  end

  test "requests without a token are unauthorized" do
    get api_time_entries_path, as: :json

    assert_response :unauthorized
  end

  test "a user manages their own time entries" do
    assert_difference("regular.time_entries.count") do
      post api_time_entries_path, params: { time_entry: { date: "2026-11-04", distance_km: 3, duration_seconds: 900 } },
                                  headers: auth(regular), as: :json
    end
    assert_response :created

    entry = time_entries(:regular_run)
    patch api_time_entry_path(entry), params: { time_entry: { distance_km: 6 } }, headers: auth(regular), as: :json
    assert_response :success
    assert_equal 6, entry.reload.distance_km
  end

  test "a regular user cannot read another user's time entry" do
    get api_time_entry_path(time_entries(:other_run)), headers: auth(regular), as: :json

    assert_response :forbidden
  end

  test "a regular user cannot change another user's time entry" do
    entry = time_entries(:other_run)

    patch api_time_entry_path(entry), params: { time_entry: { distance_km: 1 } }, headers: auth(regular), as: :json

    assert_response :forbidden
    assert_equal 10, entry.reload.distance_km
  end

  test "a regular user cannot delete another user's time entry" do
    entry = time_entries(:other_run)

    assert_no_difference("TimeEntry.count") do
      delete api_time_entry_path(entry), headers: auth(regular), as: :json
    end

    assert_response :forbidden
  end

  test "a regular user cannot create a time entry for another user" do
    assert_no_difference("TimeEntry.count") do
      post api_time_entries_path,
           params: { time_entry: { user_id: other.id, date: "2026-11-04", distance_km: 3, duration_seconds: 900 } },
           headers: auth(regular), as: :json
    end

    assert_response :forbidden
  end

  test "a regular user only sees their own weekly report" do
    get api_reports_weekly_path, params: { user_id: other.id }, headers: auth(regular)

    assert_response :success
    assert_equal [5.0], response.parsed_body.map { |row| row["total_distance_km"] }
  end

  test "a regular user cannot list users" do
    get api_users_path, headers: auth(regular), as: :json

    assert_response :forbidden
  end

  test "a regular user cannot create users" do
    assert_no_difference("User.count") do
      post api_users_path, params: new_user_params("admin"), headers: auth(regular), as: :json
    end

    assert_response :forbidden
  end

  test "a regular user cannot read or change another user" do
    get api_user_path(other), headers: auth(regular), as: :json
    assert_response :forbidden

    patch api_user_path(other), params: { user: { name: "Changed" } }, headers: auth(regular), as: :json
    assert_response :forbidden
    assert_equal "Other Regular", other.reload.name
  end

  test "a regular user cannot delete users" do
    assert_no_difference("User.count") do
      delete api_user_path(other), headers: auth(regular), as: :json
    end

    assert_response :forbidden
  end

  test "a regular user can update their profile but not their role" do
    patch api_user_path(regular), params: { user: { name: "Renamed" } }, headers: auth(regular), as: :json
    assert_response :success
    assert_equal "Renamed", regular.reload.name

    patch api_user_path(regular), params: { user: { role: "admin" } }, headers: auth(regular), as: :json
    assert_response :forbidden
    assert_equal "regular", regular.reload.role
  end

  test "a user manager creates regular users but not admins" do
    assert_difference("User.count") do
      post api_users_path, params: new_user_params("regular"), headers: auth(manager), as: :json
    end
    assert_response :created

    assert_no_difference("User.count") do
      post api_users_path, params: new_user_params("admin").deep_merge(user: { email: "admin2@example.com" }),
                           headers: auth(manager), as: :json
    end
    assert_response :forbidden
  end

  test "a user manager cannot promote anyone to admin" do
    patch api_user_path(manager), params: { user: { role: "admin" } }, headers: auth(manager), as: :json

    assert_response :forbidden
    assert_equal "user_manager", manager.reload.role
  end

  test "a user manager cannot change or delete an admin" do
    patch api_user_path(admin), params: { user: { name: "Changed" } }, headers: auth(manager), as: :json
    assert_response :forbidden
    assert_equal "Admin", admin.reload.name

    assert_no_difference("User.count") do
      delete api_user_path(admin), headers: auth(manager), as: :json
    end
    assert_response :forbidden
  end

  test "an admin can assign the admin role and delete users" do
    patch api_user_path(manager), params: { user: { role: "admin" } }, headers: auth(admin), as: :json
    assert_response :success
    assert_equal "admin", manager.reload.role

    assert_difference("User.count", -1) do
      delete api_user_path(other), headers: auth(admin), as: :json
    end
    assert_response :no_content
  end

  test "nobody can delete their own account" do
    assert_no_difference("User.count") do
      delete api_user_path(admin), headers: auth(admin), as: :json
    end

    assert_response :forbidden
  end
end
