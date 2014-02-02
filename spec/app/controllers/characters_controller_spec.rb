require 'spec_helper'

describe "CharactersController" do
  describe "#list" do
    let(:user) { create(:user) }
    let(:character) { create(:character) }

    let(:pattern) {{
        previous_page: 0,
        next_page: 0,
        has_more: false,
        characters: 2.times.map{{
            id: Integer,
            name: character.name,
            radius: character.radius,
            precision: character.precision,
            cost: character.cost,
            distance: character.distance
          }
        }
      }
    }
    
    before do
      character.save
      create(:character)
      get "characters/list", nil, token_auth_header(user.token)
    end

    it_behaves_like "response"
    it_behaves_like "json"
  end
end
