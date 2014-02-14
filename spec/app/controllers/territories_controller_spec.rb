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
  let(:ter_pattern) {
    {
      territory_id: :territory_id,
      latitude: Float,
      longitude: Float,
      owner_id: user.id,
      expiration_date: wildcard_matcher,
      created_at: wildcard_matcher,
      updated_at: wildcard_matcher,
      character_id: Integer,
      precision: Float,
      radius: Float,
      detection_count: Integer
    }
  }

  describe "#create" do
    let(:params) {
      {
        latitude: loc.coordinate.lat,
        longitude: loc.coordinate.long,
        character_id: char.id
      }
    }
    let(:pattern) {
      {
        id: :territory_id,
        owner: {
          id: user.id,
          name: user.name,
          gps_point: 401,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        character: {
          id: char.id,
          name: char.name,
          distance: char.distance
        },
        coordinate: {
          lat: Float,
          long: Float,
        },
        precision: Float,
        radius: Float,
        detection_count: Integer,
        expiration_date: wildcard_matcher,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
      }
    }

    before do
      post "/territories/create", params, token_auth_header(user.token)
      user.reload
      @json = JSON.parse last_response.body
    end

    it_behaves_like "response"
    it_behaves_like "json"

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

      params = {id: ter.id}
      get "/territories/detections", params, token_auth_header(user.token)
    end

    it_behaves_like "response"

    it "Detectionが取得できる" do
      json = JSON.parse last_response.body
      expect(json["locations"].map{|l| l["location_id"]}).to include(loc.id)
    end
  end

  describe "#move" do
    let(:params) {
      {
        latitude: 0, longitude: 0,
        id: ter.id
      }
    }

    let(:pattern) {
      {
        id: :territory_id,
        owner: {
          id: user.id,
          name: user.name,
          gps_point: user.gps_point,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        character: {
          id: ter.character.id,
          name: ter.character.name,
          distance: ter.character.distance
        },
        coordinate: {
          lat: params[:latitude],
          long: params[:longitude],
        },
        precision: Float,
        radius: Float,
        detection_count: Integer,
        expiration_date: wildcard_matcher,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
      }
    }

    before do
      user.my_territories << ter
      post "/territories/move", params, token_auth_header(user.token)
      ter.reload
    end

    it_behaves_like "response"
    it_behaves_like "json"
    it "テリトリーが移動する" do
      expect(ter.coordinate.lat).to eq(params[:latitude])
      expect(ter.coordinate.long).to eq(params[:longitude])
    end
  end

  describe "#supply" do
    let(:params) { {id: ter.id, gps_point: 30} }

    let(:pattern) {
      {
        id: :territory_id,
        owner: {
          id: user.id,
          name: user.name,
          gps_point: 471,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        character: {
          id: ter.character.id,
          name: ter.character.name,
          distance: ter.character.distance
        },
        coordinate: {
          lat: Float,
          long: Float,
        },
        precision: Float,
        radius: Float,
        detection_count: Integer,
        expiration_date: wildcard_matcher,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
      }
    }

    before do
      user.my_territories << ter
      @expiration_date = ter.expiration_date
      post "/territories/supply", params, token_auth_header(user.token)
      ter.reload
    end

    it_behaves_like "response"
    it_behaves_like "json"

    it "テリトリーの有効時間が増加する" do
      expect(ter.expiration_date).to be > @expiration_date
    end
  end
end
