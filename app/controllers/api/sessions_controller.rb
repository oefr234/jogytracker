class Api::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password].to_s)
      token = user.rotate_api_token!
      render json: { token:, user: UserSerializer.new(user) }, status: :created
    else
      render json: { error: "Invalid email/password" }, status: :unauthorized
    end
  end

  def destroy
    authenticate!
    current_user.rotate_api_token!
    head :no_content
  end
end
