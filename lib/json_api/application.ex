defmodule JsonApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Endpoint (http/https)
      JsonApiWeb.Endpoint
    ]

    :ets.new(:users, [:bag, :public, :named_table])
    :ets.new(:stargazers, [:bag, :public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JsonApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    JsonApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
