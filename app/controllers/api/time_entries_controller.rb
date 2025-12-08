class Api::TimeEntriesController < ApplicationController
  before_action :authenticate!
  before_action :set_time_entry, only: %i[show update destroy]

  def index
    entries = if current_user.admin?
                TimeEntry.all
              else
                current_user.time_entries
              end

    entries = entries.where(user_id: params[:user_id]) if params[:user_id].present? && (current_user.admin? || current_user.user_manager?)
    entries = entries.where("date >= ?", params[:from]) if params[:from].present?
    entries = entries.where("date <= ?", params[:to]) if params[:to].present?

    render json: entries.order(date: :desc), each_serializer: TimeEntrySerializer
  end

  def show
    permit_own!(@time_entry.user_id)
    render json: @time_entry
  end

  def create
    user_id = params.dig(:time_entry, :user_id).presence || current_user.id
    permit_own!(user_id.to_i)

    time_entry = TimeEntry.new(time_entry_params.merge(user_id: user_id))
    if time_entry.save
      render json: time_entry, status: :created
    else
      render json: { errors: time_entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    permit_own!(@time_entry.user_id)
    if @time_entry.update(time_entry_params)
      render json: @time_entry
    else
      render json: { errors: @time_entry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    permit_own!(@time_entry.user_id)
    @time_entry.destroy
    head :no_content
  end

  private

  def set_time_entry
    @time_entry = TimeEntry.find(params[:id])
  end

  def time_entry_params
    params.require(:time_entry).permit(:date, :distance_km, :duration_seconds, :location)
  end

end
