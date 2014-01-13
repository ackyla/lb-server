# -*- coding: utf-8 -*-
require 'spec_helper'

describe "TerritoriesController" do
  let(:loc) { create(:location) }
  let(:user) {
    u = create(:user)
    u.add_location(loc)
    u
  }
  let(:ter) { create(:territory) }
  let(:char) { create(:character) }

  describe "#create" do
    let(:params) {
      {
        latitude: loc.coordinate.lat,
        longitude: loc.coordinate.long,
        user_id: user.id, token: user.token,
        character_id: char.id
      }
    }
    let(:pattern) {
      {
        user: {
          user_id: user.id,
          token: wildcard_matcher,
          name: user.name,
          gps_point: 401,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        territory: {
          territory_id: :territory_id,
          radius: char.radius,
          owner_id: user.id,
          character_id: char.id,
          expiration_date: wildcard_matcher,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          precision: char.precision,
          detection_count: Integer,
          coordinate_id: Integer
        }
      }
    }

    before do
      post "/territories/create", params
      user.reload
      @json = JSON.parse last_response.body
    end

    it_behaves_like "response"
    it_behaves_like "json"

    it "テリトリーの検証" do
      created_territory = Territory.find(@json["territory"]["territory_id"])
      expect(user.my_territories).to include(created_territory)
    end

    it "テリトリーが追加される" do
      matcher = JsonExpressions::Matcher.new(pattern)
      matcher =~ @json
      expect(user.my_territories).to include(Territory.find(matcher.captures[:territory_id]))
    end
  end

  describe "#detections" do
    let(:loc) { create(:location) }

    before do
      @det = Detection.create(territory: ter, location: loc)
      ter.detections << @det
      user.my_territories << ter
      ter.save
      ter.reload

      params = {id: ter.id, user_id: user.id, token: user.token}
      get "/territories/detections", params
    end

    it_behaves_like "response"

    it "Detectionが取得できる" do
      json = JSON.parse last_response.body
      expect(json["locations"].map{|l| l["location_id"]}).to include(loc.id)
    end
  end

  describe "#move" do
    it "move territory" do
      user.my_territories << ter
      params = {
        latitude: 0, longitude: 0,
        id: ter.id, user_id: user.id, token: user.token
      }

      post "/territories/move", params
      ter.reload

      expect(last_response).to be_ok
      expect(ter.coordinate.lat).to eq(params[:latitude])
      expect(ter.coordinate.long).to eq(params[:longitude])
    end
  end

  describe "#supply" do
    let(:params) { {user_id: user.id, token: user.token, id: ter.id, gps_point: 30} }
    let(:pattern) {
      {
        status: "ok",
        supplied_point: Integer,
        user: {
          user_id: @user.id,
          token: wildcard_matcher,
          name: @user.name,
          gps_point: 471,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        territory: {
          territory_id: :territory_id,
          radius: Float,
          owner_id: @user.id,
          character_id: Integer,
          expiration_date: wildcard_matcher,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          precision: Float,
          detection_count: Integer,
          coordinate_id: Integer
        }
      }
    }

    before do
      @user = user
      @user.my_territories << ter
      @expiration_date = ter.expiration_date
      post "/territories/supply", params
      ter.reload
    end

    it_behaves_like "response"
    it_behaves_like "json"

    it "テリトリーの有効時間が増加する" do
      expect(ter.expiration_date).to be > @expiration_date
    end
  end
end
