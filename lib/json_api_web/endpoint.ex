defmodule JsonApiWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :json_api

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug JsonApiWeb.Router
end
