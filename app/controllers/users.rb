Server::App.controllers :users do
  helpers do
    def find_user(params)
      invalid_param_error unless params.key? "user_id"
      user = User.find_by_id(params[:user_id])
      error_message(201, "USER NOT FOUND") unless user
      return user
    end
  end

  before :show, :territories, :notifications, :locations, :avatar do
    login(params)
  end

  get :create do
    @user = User.new
    render 'users/create'
  end

  post :create, :provides => :json do
    @user = User.create(:name => params[:name])
    @user.to_json(:absolute_url => uri(@user.avatar.url))
  end

  get :show, :provides => :json do
    @user.to_json(:except => :token, :absolute_url => uri(@user.avatar.url))
  end

  get :territories, :provides => :json do
    JSON.unparse @user.my_territories.map(&:to_hash)
  end

  get :notifications, :provides => :json do
    notifications =
      if not params[:all]
        @user.notifications.undelivered.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      else
        @user.notifications.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      end

    JSON.unparse notifications
  end

  get :locations, :provides => :json do
    locations = Location.where("user_id = ? AND created_at >= ? AND created_at < ?", @user.id, Date.parse(params[:date]), Date.parse(params[:date])+1)
    locations.to_json
  end

  post :avatar, :provides => :json do
    @user.avatar = params[:avatar]
    @user.save
    @user.to_json(:except => :token, :absolute_url => uri(@user.avatar.url))
  end
end
