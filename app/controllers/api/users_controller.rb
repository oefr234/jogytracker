class Api::UsersController < ApplicationController
  before_action :authenticate!
  before_action :require_user_manager_or_admin!, only: %i[index create destroy]
  before_action :set_user, only: %i[show update destroy]
  before_action :authorize_user_access!, only: %i[show update]
  before_action :protect_admin_accounts!, only: %i[update destroy]
  before_action :authorize_role_assignment!, only: %i[create update]

  def index
    users = User.order(:id)
    render json: users, each_serializer: UserSerializer
  end

  def show
    render json: @user
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params_for_update)
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
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

  def authorize_user_access!
    permit_own!(@user.id)
  end

  def protect_admin_accounts!
    raise Forbidden if @user.admin? && !current_user.admin?
  end

  def authorize_role_assignment!
    role = params.dig(:user, :role)
    return if role.blank? || current_user.admin?

    raise Forbidden if current_user.regular? || role == "admin"
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
