# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config(:teaminterface, Teaminterface.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "0k6l1s0QQp0bTW/2uldRk0nt2bHzIji+YiQatHsfxiDkgDapxMR9TajBiEHQ7N84",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Teaminterface.PubSub,
           adapter: Phoenix.PubSub.PG2])

config(:teaminterface,
       ecto_repos: [Teaminterface.Repo],
       namespace: Teaminterface)



# Configures Elixir's Logger
config(:logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id])



# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine

config :teaminterface, Teaminterface.Web,
  contest: "DEF CON CTF 2016"

config :scrivener_html,
  routes_helper: Teaminterface.Router.Helpers
