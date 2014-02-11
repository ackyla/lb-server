Server::App.controllers :locations do
  
  before do
    login
  end

  post :create, :provides => :json do
    coord = Coordinate.find_or_create(lat: params[:latitude], long: params[:longitude])
    loc = Location.new(coordinate: coord)
    @user.add_location(loc)
    if @user.invalid?
      @errors = @user.errors
      halt 422
    end

    ters = Territory.actives.where("owner_id != ?", @user.id).select{|ter|
      ter.add_location(loc)
    }
    
    enemies = @user.enemy_territories.to_a
    new_ters = (ters - enemies)
    Invasion.destroy_all(user_id: @user.id, territory_id: (enemies - ters).map{|t| t.id})
    
    new_ters.each{|ter|
      ter.detect(@user, loc)
    }

    location_hash = JSON.parse(loc.to_json(:only => [:id, :created_at, :updated_at]))
    location_hash["user"] = JSON.parse(@user.to_json(:only => [:id, :name, :gps_point, :gps_point_limit, :level, :exp, :created_at, :updated_at, :avatar], :absolute_url => uri(@user.avatar.url, true, false)))
    location_hash["coordinate"] = JSON.parse(loc.coordinate.to_json(:only => [:lat, :long]))
    location_hash.to_json
  end
end
