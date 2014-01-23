class Location < ActiveRecord::Base
  belongs_to :user
  belongs_to :coordinate
  has_many :detections
  has_and_belongs_to_many :territories

  def to_hash
    hash = Hash[self.attributes]
    hash[:location_id] = self.id
    hash.delete "id"
    hash[:latitude] = self.coordinate.lat
    hash[:longitude] = self.coordinate.long
    hash.delete "coordinate_id"
    hash
  end
end
