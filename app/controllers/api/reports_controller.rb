class Api::ReportsController < ApplicationController
  before_action :authenticate!

  def weekly
    entries = if current_user.admin? || current_user.user_manager?
                TimeEntry.all
              else
                current_user.time_entries
              end

    entries = entries.where(user_id: params[:user_id]) if params[:user_id].present? && (current_user.admin? || current_user.user_manager?)
    entries = entries.where("date >= ?", params[:from]) if params[:from].present?
    entries = entries.where("date <= ?", params[:to]) if params[:to].present?

    rows = entries
             .select("strftime('%Y', date) AS year_str,
               strftime('%W', date) AS week_str,
               SUM(distance_km) AS total_distance_km,
               AVG(distance_km) AS avg_distance_km,
               SUM(duration_seconds) AS total_duration_seconds")
             .group("year_str, week_str")
             .order("year_str DESC, week_str DESC")

    data = rows.map do |r|
      hours = r.total_duration_seconds.to_f / 3600.0
      avg_speed = hours.zero? ? 0 : (r.total_distance_km.to_f / hours)
      {
        year: r.year_str.to_i,
        week: r.week_str.to_i,
        total_distance_km: r.total_distance_km.to_f.round(2),
        avg_distance_km: r.avg_distance_km.to_f.round(2),
        avg_speed_kmh: avg_speed.round(2)
      }
    end

    render json: data
  end
end
