Server::App.controllers :notifications do
  before :read do
    login params
    @notification = Notification.find_by_id(params[:id])
  end

  post :read, :provides => :json do
    @notification.read = true
    @notification.save
    @notification.to_json(:only => [:id, :notification_type, :read, :created_at, :updated_at])
  end
end
