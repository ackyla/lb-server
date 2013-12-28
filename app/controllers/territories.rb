Server::App.controllers :territories do
  before :create, :destroy, :locations do
    login(params)
  end

  post :create, :provides => :json do
    territory = Territory.new(
      :latitude => params[:latitude],
      :longitude => params[:longitude],
      :radius => params[:radius]
      ){|territory|
      territory.user = @user
    }
    territory.save
    territory.to_json
  end

  post :destroy, :provides => :json do
    territory = Territory.find_by_id(params[;id])
    @territory.expire
    @territory.to_json
  end

  get :locations, :provides => :json do
    territory = Territory.find_by_id(params[:id])
    territory.locations.to_json
  end
end
