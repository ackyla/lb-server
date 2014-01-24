# -*- coding: utf-8 -*-
require 'spec_helper'

describe "UsersController" do
  let(:user) { create(:user) }
  let(:user_param) { {user_id: user.id, token: user.token} }
  let(:user_pattern) {
    {
      id: user.id,
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
    let(:params) {{name: "user_1"}}
    let(:pattern) {{
        id: Integer,
        token: wildcard_matcher,
        name: params[:name],
        gps_point: Integer,
        gps_point_limit: Integer,
        level: Integer,
        exp: Integer,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
        avatar: /http.*.(jpg|jpeg)/
      }
    }

    before { post "/users/create", params }
    it_behaves_like "response"
    it_behaves_like "json"
  end

  describe "#show" do
    describe "#valid_user_id" do
      let(:pattern) { user_pattern }
      before { get "/users/show", {user_id: user.id, token: user.token} }
      it_behaves_like "response"
      it_behaves_like "json"
    end

    describe "#parameter_not_found" do
      before { get "/users/show" }
      it_behaves_like "404"
    end

    describe "#invalid_user_id" do
      before { get "/users/show", {user_id: 999, token: user.token} }
      it_behaves_like "401"
    end

    describe "#invalid_token" do
      before { get "/users/show", {user_id: user.id, token: "hogefugaga"} }
      it_behaves_like "401"
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

    it_behaves_like "response"

    it "JSONが正常" do
      ret = @json[0]
      %w(longitude latitude).each{|key|
        expect(ret["location"][key]).to eq(@loc.to_hash[key.to_sym])
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

    it_behaves_like "response"

    it "長さが2" do
      expect(@json.length).to eq(2)
    end
  end

  describe "#territories" do
    let(:char) {create(:character)}
    let(:latlong) {{latitude: 35.0, longitude: 135.8}}
    let(:ter_pattern) {
      latlong.merge({
          territory_id: Integer,
          owner_id: user.id,
          character_id: char.id,
          radius: char.radius,
          precision: char.precision,
          expiration_date: wildcard_matcher,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          detection_count: Integer
          # coordinate_id: Integer,
        })
    }

    before do
      loc = create(:location)
      user.locations << loc
      2.times{
        user.add_territory(latlong[:latitude], latlong[:longitude], char.id)
      }
      user.save
      get "/users/territories", user_param
      @json = JSON.parse last_response.body
    end

    it_behaves_like "response"
    it_behaves_like "json" do
      let(:pattern){ [ter_pattern] * 2 }
    end
  end

  describe "#avatar" do
    let(:pattern) { user_pattern }
    let(:params) { user_param.merge({avatar: File.open(Padrino.root('public/avatars', 'default_avatar.jpg'))}) }
    before do
      post "/users/avatar", params
    end

    it_behaves_like "response"
    it_behaves_like "json"
  end
end
