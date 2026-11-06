class ApplicationController < ActionController::Base
  class Forbidden < StandardError; end

  protect_from_forgery with: :null_session
  before_action :set_default_format
  rescue_from Forbidden, with: :render_forbidden

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

  # Raising stops the action, so these checks also work when called from inside one.
  def require_user_manager_or_admin!
    return if current_user&.admin? || current_user&.user_manager?
    raise Forbidden
  end

  def permit_own!(resource_user_id)
    return if current_user&.admin? || current_user&.user_manager? || current_user&.id == resource_user_id
    raise Forbidden
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
