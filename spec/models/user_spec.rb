# -*- coding: utf-8 -*-
require 'spec_helper'

describe User do
  let(:loc) { create(:location) }
  let(:char) { create(:character) }
  let(:user) { create(:user) }


  describe "#add_territory" do
    before do
      user.add_location(loc)
      @point = user.gps_point
      @ter = user.add_territory(35.0, 135.8, char.id)
    end

    it "テリトリーが追加される" do
      expect(user.my_territories).to include(@ter)
    end

    it "GPSポイントが消費される" do
      expect(user.gps_point).to eq(@point - char.cost)
    end
  end

  describe "#add_location" do
    before do
      @point = user.gps_point
      user.add_location(loc)
    end

    it "ロケーションが生成される" do
      expect(user.locations).to include(loc)
    end

    it "GPSポイントが増える" do
      expect(user.gps_point).to be > @point
    end
  end

  describe "#add_exp" do
    it "経験値が増加する" do
      user.add_exp 10
      expect(user.exp).to eq(10)
    end

    describe "レベルアップ処理" do
      before do
        user.add_exp 110
      end

      it "レベルアップする" do
        expect(user.level).to eq(2)
      end

      it "陣力が増加する" do
        expect(user.gps_point).to eq(user.gps_point_limit)
      end
    end
  end

  describe "#use_point" do
    before do
      user.gps_point = 100
    end

    context "ポイント以下の場合" do
      it "ポイントを消費する" do
        expect(user.use_point(30)).to be_true
        expect(user.gps_point).to eq(70)
      end
    end

    context "ポイント以上の場合" do
      it "ポイントを消費しない" do
        expect(user.use_point(110)).to be_false
        expect(user.gps_point).to eq(100)
      end
    end

    context "ポイントが負の場合" do
      it "Falseを返す" do
        expect(user.use_point(-10)).to be_false
        expect(user.gps_point).to eq(100)
      end
    end
  end

  describe "#update_avatar" do
    before do
      user.avatar = File.open Padrino.root('public/avatars', 'default_avatar.jpg')
      user.save
    end

    it "アバターが設定される" do
      expect(user.avatar.file).not_to be_nil
      expect(File.exists? user.avatar.file.file).to be_true
    end
  end
end
