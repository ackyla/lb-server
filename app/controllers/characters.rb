Server::App.controllers :characters do
  get :list, provides: :json do
    Character.all.to_json(:except => [:created_at, :updated_at])
  end
end
