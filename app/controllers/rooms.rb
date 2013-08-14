# -*- coding: utf-8 -*-
Server::App.controllers :rooms do

  before :create, :enter, :start, :hit, :result do
    login(params)
  end

  before :enter, :show, :users, :timelimit do
    find_room(params)
  end

  post :create, :provides => :json do
    invalid_param_error unless params.key? "title"
    room = Room.new(:title => params[:title]){|r|
      r.time_limit = params[:time_limit] if params[:time_limit]
      r.owner = @user
    }.save
    @user.enter_room(room)
    room.to_json
  end

  get :show, :provides => :json do
    @room.to_json
  end

  get :list, :provides => :json do
    Room.order('created_at desc').limit(20).to_json
  end

  get :users, :provides => :json do
    @room.users.to_json
  end

  get :timelimit, :provides => :json do
    (@room.termination_time.to_time - Time.now).to_i
  end

  get :result, :provides => :json do

  end
end
