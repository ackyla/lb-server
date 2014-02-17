Server::App.controllers :characters do

  before :list do
    login
  end

  get :list, provides: :json do
    characters = Character.page(@page).per(@per)

    previous_page = characters.prev_page ? characters.prev_page : 0
    next_page = characters.next_page ? characters.next_page : 0
    has_more = characters.last_page? ? false : true
    {
      previous_page: previous_page,
      next_page: next_page,
      has_more: has_more,
      characters: characters.map(&:response_hash)
    }.to_json
  end
end
