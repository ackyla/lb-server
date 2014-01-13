# -*- coding: utf-8 -*-
require 'spec_helper'

describe "NotificationsController" do
  let(:user) { create(:user) }
  let(:loc) { create(:location) }
  let(:user2) {
    u = build(:user2)
    u.locations << loc
    u.save
    u
  }
  let(:ter) {
    t = build(:territory)
    t.owner = user2
    t.save
    t
  }
  let(:notif_pattern1) {
    {
      notification_id: Integer,
      notification_type: "detection",
      user_id: 2,
      detection_id: Integer,
      delivered: true,
      read: false,
      territory: {
        territory_id: 1,
        owner_id: 2,
        character_id: Integer,
        precision: Float,
        radius: Float,
        detection_count: Integer,
        expiration_date: wildcard_matcher,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
        latitude: Float,
        longitude: Float
      },
      created_at: wildcard_matcher,
      updated_at: wildcard_matcher
    }
  }
  let(:notif_pattern2) {
    {
      notification_id: Integer,
      notification_type: "entering",
      user_id: 1,
      detection_id: Integer,
      created_at: wildcard_matcher,
      updated_at: wildcard_matcher,
      delivered: true,
      read: false,
      location: {
        location_id: Integer,
        user_id: 2,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher,
        latitude: Float,
        longitude: Float
      },
      territory_owner: {
        user_id: 2,
        token: wildcard_matcher,
        name: wildcard_matcher,
        exp: Integer,
        level: Integer,
        gps_point: Integer,
        gps_point_limit: Integer,
        avatar: /http.*.(jpg|jpeg)/,
        created_at: wildcard_matcher,
        updated_at: wildcard_matcher
      }
    }
  }


  describe "#read" do
    let(:det) {Detection.create(location: loc, territory: ter)}
    let(:notif) {Notification.create(user: user, detection: det, notification_type: "entering")}

    before do
      params = {
        user_id: user.id,
        token: user.token,
        notification_id: notif.id
      }
      post '/notifications/read', params
      notif.reload
    end

    it_behaves_like "response"

    it "既読になる" do
      expect(notif.read).to eq(true)
    end
  end

  describe "#list" do
    let(:det) {Detection.create(location: loc, territory: ter)}
    let(:notif1) {Notification.create(user: user2, detection: det, notification_type: "detection")}
    let(:notif2) {Notification.create(user: user, detection: det, notification_type: "entering")}

    before do
      notif1.reload
      notif2.reload

      params = {user_id: user.id, token: user.token, all: true}
      get '/users/notifications', params
      @json1 = JSON.parse last_response.body

      params = {user_id: user2.id, token: user2.token, all: true}
      get '/users/notifications', params
      @json2 = JSON.parse last_response.body
    end

    it "jsonチェックdetection" do
      expect(@json2[0]).to match_json_expression(notif_pattern1)
    end

    it "jsonチェックentering" do
      expect(@json1[0]).to match_json_expression(notif_pattern2)
    end
  end
end
