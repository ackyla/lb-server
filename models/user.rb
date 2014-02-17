require 'securerandom'

class User < ActiveRecord::Base
  has_many :locations, dependent: :destroy
  has_many :my_territories, class_name: "Territory", foreign_key: 'owner_id', dependent: :destroy
  has_many :invasions, dependent: :destroy
  has_many :enemy_territories, class_name: "Territory", through: :invasions, source: :territory
  has_many :notifications, dependent: :destroy

  mount_uploader :avatar, AvatarUploader

  validates :name,
  :presence => true,
  :length => { :in => 1..20 }

  validates :gps_point,
  :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => :gps_point_limit }

  before_create do
    token = SecureRandom.base64(16)
    self.token = token
  end

  def add_territory(latitude, longitude, character_id)
    character = Character.find(character_id)
    return unless character
    return if character.cost > self.gps_point

    coord = Coordinate.find_or_create(lat: latitude, long: longitude)
    ter = self.my_territories.new(character: character, coordinate: coord)
    return unless ter.within_range(locations.last.coordinate)

    self.gps_point -= character.cost
    return (save and ter)
  end

  def add_location(loc)
    locations << loc
    return if loc.invalid?
    self.gps_point += 1 if self.gps_point < self.gps_point_limit
    save
  end

  def use_point(point)
    return false if (point < 1 or self.gps_point < point)
    self.gps_point -= point
    save
  end

  def add_exp(exp_point)
    self.exp += exp_point
    level_up if level_up?
    self.save
  end

  def to_hash(options=nil)
    hash = Hash[self.attributes]
    hash["user_id"] = self.id
    hash["avatar"] = options && options[:absolute_url] ? options[:absolute_url] : self.avatar.url
    hash.delete "id"
    hash
  end

  def to_json(options=nil)
    params = JSON.parse ActiveSupport::JSON.encode(self, options)
    if params["avatar"]
      params["avatar"] = options && options[:absolute_url] ? options[:absolute_url] : self.avatar.url
    end
    ActiveSupport::JSON.encode(params, nil)
  end

  private
  def level_up?
    self.exp > (self.level * 100)
  end

  def level_up
    self.gps_point = self.gps_point_limit
    self.level = self.exp / 100 + 1
  end

end
