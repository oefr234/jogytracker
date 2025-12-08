class TimeEntry < ApplicationRecord
  belongs_to :user

  validates :date, presence: true
  validates :distance_km, numericality: { greater_than: 0 }
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0 }

  def avg_speed_kmh
    hours = duration_seconds.to_f / 3600.0
    return 0 if hours.zero?
    (distance_km.to_f / hours).round(2)
  end
end
