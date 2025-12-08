class Api::UsersController < ApplicationController
  before_action :authenticate!
  before_action :set_user, only: %i[show update destroy]

  def index
    require_user_manager_or_admin!
    users = User.order(:id)
    render json: users, each_serializer: UserSerializer
  end

  def show
    if current_user.admin? || current_user.user_manager? || current_user.id == @user.id
      render json: @user
    else
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def create
    require_user_manager_or_admin!
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if current_user.admin? || current_user.user_manager? || current_user.id == @user.id
      if current_user.regular? && params.dig(:user, :role).present?
        return render json: { error: "Forbidden" }, status: :forbidden
      end

      if @user.update(user_params_for_update)
        render json: @user
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def destroy
    require_user_manager_or_admin!

    if current_user.id == @user.id
      return render json: { error: "You cannot delete your own account." }, status: :forbidden
    end

    @user.destroy
    head :no_content
  end


  private

  def set_user
    @user = User.find(params[:id])
  end

  def base_user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end

  def user_params
    p = base_user_params
    p[:email] = p[:email].to_s.downcase if p[:email]
    p
  end

  def user_params_for_update
    permitted = %i[name email password password_confirmation]
    permitted << :role if current_user.admin? || current_user.user_manager?
    p = params.require(:user).permit(*permitted)
    p[:email] = p[:email].to_s.downcase if p[:email]
    p
  end
end
