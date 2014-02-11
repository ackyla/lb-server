class Location < ActiveRecord::Base
  belongs_to :user
  belongs_to :coordinate
  has_many :detections
  has_and_belongs_to_many :territories
  MINIMUM_TIME_INTERVAL = 300

  validate :validate_interval, :if => :user_id, :on => :create

  def to_hash
    hash = Hash[self.attributes]
    hash[:location_id] = self.id
    hash.delete "id"
    hash[:latitude] = self.coordinate.lat
    hash[:longitude] = self.coordinate.long
    hash.delete "coordinate_id"
    hash
  end

  private
  def validate_interval
    recent_location = user.locations.order(Location.arel_table[:created_at].desc).first
    if recent_location
      time_interval = Time.now - recent_location.created_at
      if time_interval < MINIMUM_TIME_INTERVAL
        errors.add(:created_at, "time interval is below #{MINIMUM_TIME_INTERVAL}")
      end
    end
  end
end
