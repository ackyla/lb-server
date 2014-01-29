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

  describe "#read" do
    let(:det) {Detection.create(location: loc, territory: ter)}
    let(:notif) {Notification.create(user: user, detection: det, notification_type: "entering")}

    before do
      params = {
        notification_id: notif.id
      }
      post '/notifications/read', params, token_auth_header(user.token)
      notif.reload
    end

    it_behaves_like "response"

    it "既読になる" do
      expect(notif.read).to eq(true)
    end
  end
end
