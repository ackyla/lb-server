class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :detection
  scope :unread, conditions: {read: false}
  scope :undelivered, conditions: {delivered: false}

  def deliver
    self.update_attributes(:delivered => true) if self.delivered == false
  end

  def notification_info(options=nil)
    if self.delivered == false
      self.delivered = true
      self.save
    end

    case self.notification_type
    when "entering"
      {
        location: self.detection.location.to_hash,
        territory_owner: self.detection.territory.owner.to_hash(options)
      }
    when "detection"
      {territory: self.detection.territory.to_hash}
    end.merge(self.to_hash)
  end

  def to_hash
    hash = Hash[self.attributes]
    hash["notification_id"] = self.id
    hash.delete "id"
    hash
  end
end
