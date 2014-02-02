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
    describe "#valid_name" do
      let(:pattern) {{
          id: Integer,
          token: wildcard_matcher,
          name: "user_1"
        }
      }
      
      before { post "/users/create", {name: "user_1"} }
      it_behaves_like "response"
      it_behaves_like "json"
    end
    
    describe "#parameter_not_found" do
      before { post "/users/create" }
      it_behaves_like "404"
    end

    describe "#name_is_too_short" do
      before { post "/users/create", {name: ""} }
      it_behaves_like "422", 1
    end

    describe "#name_is_too_long" do
      before { post "/users/create", {name: "1234567890123456789012345"} }
      it_behaves_like "422", 1
    end

  end

  describe "#show" do
    describe "#valid_token" do
      let(:pattern) { user_pattern }
      before { get "/user/show", nil, token_auth_header(user.token) }
      it_behaves_like "response"
      it_behaves_like "json"
    end

    describe "#parameter_not_found" do
      before { get "/user/show" }
      it_behaves_like "404"
    end

    describe "#invalid_token" do
      before { get "/user/show", nil, token_auth_header("hogerahogera") }
      it_behaves_like "401"
    end
  end

  describe "#notifications" do
    let(:char) {create(:character)}
    let(:user2) { create(:user2) }
    let(:loc) { create(:location, :user_id => user2.id) }
    let(:ter) { create(:territory, :owner_id => user2.id, :character_id => char.id) }

    before do
      user2.reload
    end

    describe "#entering" do
      let(:pattern) {{
          previous_page: 0,
          next_page: 0,
          has_more: false,
          notifications:
          [{
             id: Integer,
             notification_type: "entering",
             created_at: wildcard_matcher,
             updated_at: wildcard_matcher,
             read: false,
             location: {
               id: Integer,
               created_at: wildcard_matcher,
               updated_at: wildcard_matcher,
               coordinate: {
                 lat: Float,
                 long: Float
               }
             },
             territory_owner: {
               id: 2,
               name: wildcard_matcher,
               level: Integer,
               avatar: /http.*.(jpg|jpeg)/,
               created_at: wildcard_matcher,
               updated_at: wildcard_matcher
             }
           }
          ]
        }
      }
      before do
        det = Detection.create(location: loc, territory: ter)
        Notification.create(user: user, detection: det, notification_type: "entering")
        get "/user/notifications", {all: true}, token_auth_header(user.token)
      end
      it_behaves_like "response"
      it_behaves_like "json"
    end

    describe "#detection" do
      let(:pattern) {{
          previous_page: 0,
          next_page: 0,
          has_more: false,
          notifications:
          [{
             id: Integer,
             notification_type: "detection",
             read: false,
             territory: {
               id: Integer,
               character: {
                 id: char.id,
                 name: char.name
               },
               detection_count: Integer,
               coordinate: {
                 lat: Float,
                 long: Float
               },
               expiration_date: wildcard_matcher,
               created_at: wildcard_matcher,
               updated_at: wildcard_matcher,
             },
             created_at: wildcard_matcher,
             updated_at: wildcard_matcher
           }
          ]
        }
      }
      before do
        det = Detection.create(location: loc, territory: ter)
        Notification.create(user: user2, detection: det, notification_type: "detection")
        get "/user/notifications", {all: true}, token_auth_header(user2.token)
      end
      it_behaves_like "response"
      it_behaves_like "json"
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

      get "/user/locations", {date: DateTime.now.strftime("%Y-%m-%dT00:00:00%Z")}, token_auth_header(user.token)
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
    let(:pattern) {{
        previous_page: 0,
        next_page: 0,
        has_more: false,
        territories: 2.times.map{{
            id: Integer,
            character: {
              id: char.id,
              name: char.name,
              distance: char.distance
            },
            radius: char.radius,
            precision: char.precision,
            detection_count: Integer,
            coordinate: {
              lat: latlong[:latitude],
              long: latlong[:longitude]
            },
            expiration_date: wildcard_matcher,
            created_at: wildcard_matcher,
            updated_at: wildcard_matcher,
          }
        }
      }
    }

    before do
      loc = create(:location)
      user.locations << loc
      2.times{
        user.add_territory(latlong[:latitude], latlong[:longitude], char.id)
      }
      user.save
      get "/user/territories", nil, token_auth_header(user.token)
    end

    it_behaves_like "response"
    it_behaves_like "json"
  end

  describe "#avatar" do
    let(:pattern) { user_pattern }
    before do
      post "/user/avatar", {avatar: File.open(Padrino.root('public/avatars', 'default_avatar.jpg'))}, token_auth_header(user.token)
    end
    
    it_behaves_like "response"
    it_behaves_like "json"
  end
end
