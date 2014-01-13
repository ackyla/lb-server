# -*- coding: utf-8 -*-
require 'spec_helper'

describe "UsersController" do
  let(:user) { create(:user) }
  let(:user_param) { {user_id: user.id, token: user.token} }
  let(:user_pattern) {
    {
      id: user.id,
      token: wildcard_matcher,
      name: user.name,
      gps_point: Integer,
      gps_point_limit: Integer,
      level: Integer,
      exp: Integer,
      created_at: wildcard_matcher,
      updated_at: wildcard_matcher,
      avatar: /http.*.(jpg|jpeg)/
    }
  }

  describe "#create" do
    before do
      @params = {name: "user_1"}
      post "/users/create", @params
    end

    it "status check" do
      expect(last_response).to be_ok
    end

    it "ユーザ情報返す" do
      pattern = {
        id: Integer,
        token: wildcard_matcher,
        name: @params[:name],
        gps_point: Integer,
        gps_point_limit: Integer,
        level: Integer,
        exp: Integer,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
        avatar: /http.*.(jpg|jpeg)/
      }
      expect(last_response.body).to match_json_expression(pattern)
    end
  end

  describe "#show" do
    before do
      get "/users/show", {user_id: user.id}
    end

    it "status check" do
      expect(last_response).to be_ok
    end

    it "ユーザ情報取得" do
      expect(last_response.body).to match_json_expression(user_pattern)
    end
  end

  describe "#notifications" do
    before do
      @user2 = create(:user2)
      @loc = create(:location)
      @ter = create(:territory)
      @user2.my_territories << @ter
      @det = Detection.new(location: @loc, territory: @ter)
      @det.save
      @notification = Notification.new(
        user: user,
        detection: @det,
        notification_type: "entering"
        )
      @notification.save
      get "/users/notifications", user_param
      @json = JSON.parse last_response.body
    end

    it "status check" do
      expect(last_response).to be_ok
      ret = @json[0]
      %w(longitude latitude).each{|key|
        expect(ret["location"][key]).to eq(@loc[key.to_sym])
      }
      %w(user_id, name).each{|k|
        expect(ret["territory_owner"][k]).to eq(@user2[k.to_sym])
      }
    end
  end

  describe "#locations" do
    before do
      @user2 = create(:user2)
      @loc1 = create(:location)
      @loc1.update_attributes(:user => user)
      @loc2 = create(:location2)
      @loc2.update_attributes(:user => user)
      @loc3 = create(:location)
      @loc3.update_attributes(:user => user, :created_at => (DateTime.now-1))

      @loc4 = create(:location)
      @loc4.update_attributes(:user => @user2)

      get "/users/locations", user_param.merge({date: DateTime.now.strftime("%Y-%m-%dT00:00:00%Z")})
      @json = JSON.parse last_response.body
    end

    it "status check" do
      expect(last_response).to be_ok
      expect(@json.length).to eq(2)
    end
  end

  describe "#avatar" do
    before do
      post "/users/avatar", user_param.merge({avatar: File.open(Padrino.root('public/avatars', 'default_avatar.jpg'))})
    end

    it "status check" do
      expect(last_response).to be_ok
    end

    it "ユーザ情報返す" do
      expect(last_response.body).to match_json_expression(user_pattern)
    end
  end
end
