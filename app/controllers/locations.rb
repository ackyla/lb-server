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

    res_hash = loc.response_hash
    res_hash["user"] = @user.response_hash.merge(avatar: user_avatar_url(@user))
    res_hash.to_json
  end
end
