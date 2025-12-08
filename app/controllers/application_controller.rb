class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :set_default_format

  private

  def set_default_format
    request.format = :json if request.path.start_with?("/api")
  end


  def current_user
    @current_user ||= begin
                        auth = request.headers["Authorization"].to_s
                        token = auth[/token=(.+)/, 1] || auth.split.last
                        User.find_by(api_token: token) if token.present?
                      end
  end

  def authenticate!
    return if current_user
    render json: { error: "Unauthorized" }, status: :unauthorized
  end


  def require_admin!
    return if current_user&.admin?
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def require_user_manager_or_admin!
    return if current_user&.admin? || current_user&.user_manager?
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def permit_own!(resource_user_id)
    return if current_user&.admin? || current_user&.user_manager? || current_user&.id == resource_user_id
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
