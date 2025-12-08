class TimeEntrySerializer < ActiveModel::Serializer
  attributes :id, :user_id, :date, :distance_km, :duration_seconds, :avg_speed_kmh, :location, :created_at, :updated_at
  #belongs_to :user, if: -> { scope&.admin? || scope&.user_manager? }
end
