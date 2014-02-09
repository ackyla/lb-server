# -*- coding: utf-8 -*-
Server::App.controllers :territories do
  before :create do
    login(params)
  end

  before :destroy, :locations, :supply, :move, :detections do
    login(params)
    @territory = @user.my_territories.find(params[:id])
  end

  post :create, :provides => :json do
    ter = @user.add_territory(params[:latitude], params[:longitude], params[:character_id])
    if ter.invalid?
      @errors = ter.errors
      halt 422
    end

    territory_hash = JSON.parse(ter.to_json(:only => [:id, :precision, :radius, :detection_count, :expiration_date, :created_at, :updated_at]))
    territory_hash["owner"] = JSON.parse(ter.owner.to_json(:only => [:id, :name, :gps_point, :gps_point_limit, :level, :exp, :avatar, :created_at, :updated_at], :absolute_url => uri(ter.owner.avatar.url, true, false)))
    territory_hash["character"] = JSON.parse(ter.character.to_json(:only => [:id, :name, :distance]))
    territory_hash["coordinate"] = JSON.parse(ter.coordinate.to_json(:only => [:lat, :long]))

    territory_hash.to_json
  end

  post :destroy, :provides => :json do
    @territory.expire
    @territory.save
    @territory.to_json
  end

  get :locations, :provides => :json do
    @territory.locations.to_json
  end

  get :detections, provides: :json do
    ret = {territory: @territory.to_hash}
    if @territory.detections.size > 0
      ret = ret.merge({locations: @territory.detections.map{|d| d.location.to_hash }})
    end
    JSON.unparse ret
  end

  post :supply, provides: :json do
    return status_failure "GPSポイントが指定されていません." unless params[:gps_point]
    point = params[:gps_point].to_i
    return status_failure unless @territory.supply point
    return JSON.unparse(status_ok({supplied_point: point, territory: @territory.to_hash, user: @user.reload.to_hash(:absolute_url => uri(@user.avatar.url))}))
  end

  post :move, provides: :json do
    coord = Coordinate.find_or_create(lat: params[:latitude], long: params[:longitude])
    @territory.coordinate = coord
    @territory.save
    @territory.to_json
  end
end
