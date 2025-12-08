class Api::RegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    user = User.new(user_params)
    user.role = "regular"

    if user.save
      token = user.rotate_api_token!
      render json: { token:, user: UserSerializer.new(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
