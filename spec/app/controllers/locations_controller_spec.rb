# -*- coding: utf-8 -*-
require 'spec_helper'

describe "LocationsController" do
  let(:loc) { create(:location) }

  describe "#create" do
    let(:user) {
      u = create(:user)
      u.avatar = File.open(Padrino.root('public/avatars', 'default_avatar.jpg'))
      u.save
      u
    }

    let(:params) {
      {
        latitude: loc.coordinate.lat,
        longitude: loc.coordinate.long
      }
    }

    let(:pattern) {
      {
        id: :location_id,
        user: {
          id: user.id,
          name: user.name,
          gps_point: 501,
          gps_point_limit: Integer,
          level: Integer,
          exp: Integer,
          created_at: wildcard_matcher,
          updated_at: wildcard_matcher,
          avatar: /http.*.(jpg|jpeg)/
        },
        coordinate: {
          lat: Float,
          long: Float
        },
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher
      }
    }
    before do
      @pre_point = user.gps_point
      @user2 = create(:user2)
      @user2.locations << loc
      @ter = build(:territory)
      @user2.my_territories << @ter
      @ter.save
      @user2.save
      post "/locations/create", params, token_auth_header(user.token)
      user.reload
      @ter.reload
    end

    it_behaves_like "response"
    it_behaves_like "json"

    it "ロケーションの生成" do
      matcher = JsonExpressions::Matcher.new(pattern)
      matcher =~ JSON.parse(last_response.body)
      expect(user.locations).to include(Location.find(matcher.captures[:location_id]))
    end

    it "侵入状態の更新" do
      expect(user.enemy_territories).to include(@ter)
      expect(@ter.invaders).to include(user)
      expect(@ter.detection_count).to eq(1)
    end

    it "陣力の増加" do
      expect(user.gps_point).to be > @pre_point
    end

    describe "連続して#createした時" do
      before do
        @pre_point2 = user.gps_point
        post "/locations/create", params, token_auth_header(user.token)
        user.reload
        @json = JSON.parse last_response.body
      end

      it_behaves_like "422", 1

      it "陣力が増加しない" do
        expect(user.gps_point).to eq(@pre_point2)
      end
    end
  end
end
