defmodule JsonApiWeb.Router do
  use JsonApiWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(JsonApiWeb.Plug.CastParams)
  end

  scope "/api", JsonApiWeb do
    pipe_through(:api)

    post("/add_new_repo", StargazersController, :add_new_repo)
    post("/new_and_former_stargazers", StargazersController, :new_and_former_stargazers)
  end
end
