require 'spec_helper'

describe "CharactersController" do
  describe "#list" do
    let(:user) { create(:user) }
    let(:character) { create(:character) }

    let(:pattern) {
      [{
         id: character.id,
         name: character.name,
         radius: character.radius,
         precision: character.precision,
         cost: character.cost,
         distance: character.distance
       }
      ]
    }
    
    before do
      character.save
      get "characters/list", nil, token_auth_header(user.token)
    end

    it_behaves_like "response"
    it_behaves_like "json"
  end
end
