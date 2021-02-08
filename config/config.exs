# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :json_api, JsonApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jfp4/IU/7lmSACV0GMiXEboWrgjONOAs5idU9tfuybjdjHSw8vB0vfoB81NSLMOx"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
