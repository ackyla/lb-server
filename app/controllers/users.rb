Server::App.controllers :users do

  before :show, :territories, :notifications, :locations, :avatar do
    login(params)
  end

  before :territories do
    @all = params[:all] ? true : false
    @page = (params[:page] and params[:page].to_i > 0) ? params[:page] : 1
    @per = (params[:per] and params[:per].to_i > 0) ? params[:per] : 30
  end

  get :create do
    @user = User.new
    render 'users/create'
  end

  post :create, :provides => :json do
    halt 404 unless params[:name]
    user = User.create(:name => params[:name])
    if user.invalid?
      @errors = user.errors
      halt 422
    end
    user.to_json(:only => [:id, :token, :name])
  end

  get :show, :map => "/user/show", :provides => :json do
    @user.to_json(:except => :token, :absolute_url => uri(@user.avatar.url))
  end

  get :territories, :map => "/user/territories", :provides => :json do
    territories = @user.my_territories
    territories = territories.page(@page).per(@per) if !@all

    previous_page = (!@all and territories.prev_page) ? territories.prev_page : 0 
    next_page = (!@all and territories.next_page) ? territories.next_page : 0
    has_more = (!@all and territories.last_page?) ? false : true

    territories = territories.map{|t|
      obj = JSON.parse(t.to_json(:only => [:id, :radius, :precision, :detection_count, :expiration_date, :created_at, :updated_at]))
      obj["character"] = JSON.parse(t.character.to_json(:only => [:id, :name, :distance]))
      obj["coordinate"] = JSON.parse(t.coordinate.to_json(:only => [:lat, :long]))
      obj
    }

    {
      previous_page: previous_page,
      next_page: next_page,
      has_more: has_more,
      territories: territories
    }.to_json
  end

  get :notifications, :map => "/user/notifications", :provides => :json do
    notifications =
      if not params[:all]
        @user.notifications.undelivered.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      else
        @user.notifications.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      end

    JSON.unparse notifications
  end

  get :locations, :map => "/user/locations", :provides => :json do
    locations = Location.where("user_id = ? AND created_at >= ? AND created_at < ?", @user.id, Date.parse(params[:date]), Date.parse(params[:date])+1)
    locations.to_json
  end

  post :avatar, :map => "/user/avatar", :provides => :json do
    @user.avatar = params[:avatar]
    @user.save
    @user.to_json(:except => :token, :absolute_url => uri(@user.avatar.url))
  end
end
