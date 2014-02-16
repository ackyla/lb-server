Server::App.controllers :users do

  before :show, :territories, :notifications, :locations, :avatar do
    login
  end

  before :territories do
    @all = params[:all] ? true : false
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
    notifications = @user.notifications.order(Notification.arel_table[:created_at].desc)
    notifications = notifications.page(@page).per(@per)

    previous_page = notifications.prev_page ? notifications.prev_page : 0
    next_page = notifications.next_page ? notifications.next_page : 0
    has_more = notifications.last_page? ? false : true

    notifications = notifications.map{|n|
      n.deliver
      notification_hash = JSON.parse(n.to_json(:only => [:id, :notification_type, :created_at, :updated_at, :read]))
      if n.notification_type == "entering"
        loc_hash = JSON.parse(n.detection.location.to_json(:only => [:id, :created_at, :updated_at]))
        loc_hash["coordinate"] = JSON.parse(n.detection.location.coordinate.to_json(:only => [:lat, :long]))
        notification_hash["location"] = loc_hash
        notification_hash["territory_owner"] = JSON.parse(n.detection.territory.owner.to_json(:only => [:id, :name, :level, :created_at, :updated_at, :avatar], :absolute_url => uri(n.detection.territory.owner.avatar.url, true, false)))
      else
        hash = JSON.parse(n.to_json(:only => [:id, :notification_type, :created_at, :updated_at, :read]))
        territory_hash = JSON.parse(n.detection.territory.to_json(:only => [:id, :precision, :radius, :detection_count, :expiration_date, :created_at, :updated_at]))
        territory_hash["character"] = JSON.parse(n.detection.territory.character.to_json(:only => [:id, :name, :distance]))
        territory_hash["coordinate"] = JSON.parse(n.detection.territory.coordinate.to_json(:only => [:lat, :long]))
        notification_hash["territory"] = territory_hash
      end
      notification_hash
    }

=begin
    notifications =
      if not params[:all]
        @user.notifications.undelivered.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      else
        @user.notifications.map{|n| n.notification_info(:absolute_url => uri(n.detection.territory.owner.avatar.url))}
      end

    JSON.unparse notifications
=end

    {
      previous_page: previous_page,
      next_page: next_page,
      has_more: has_more,
      notifications: notifications
    }.to_json
  end

  get :locations, :map => "/user/locations", :provides => :json do
    halt 404 unless params[:date]
    begin
      date = Date.parse(params[:date])
    rescue
      halt 404
    end
    
    locations = Location.where("user_id = ? AND created_at >= ? AND created_at < ?", @user.id, date, date+1)

    pre = 0
    locations_array = Array.new
    locations.each{|l|
      c = l.coordinate
      if c.id != pre
        l_hash = JSON.parse(l.to_json(:only => [:id, :created_at, :updated_at]))
        l_hash["coordinate"] = JSON.parse(c.to_json(:only => [:lat, :long]))
        locations_array.append(l_hash)
        pre = c.id
      end
    }
    locations_array.to_json
  end

  post :avatar, :map => "/user/avatar", :provides => :json do
    @user.avatar = params[:avatar]
    @user.save
    @user.to_json(:except => :token, :absolute_url => uri(@user.avatar.url))
  end
end
