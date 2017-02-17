use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :teaminterface, Teaminterface.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :teaminterface, Teaminterface.Repo,
  adapter: Ecto.Adapters.Postgres,
  # username: "postgres",
  # password: "postgres",
  database: "teaminterface_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :comeonin,
  bcrypt_log_rounds: 4

config :teaminterface, :upload_root, "/tmp/teaminterface"

config :teaminterface, :download_root, "/tmp/teaminterface"

if System.get_env("IN_GUARD") do
  config :elixir, :ansi_enabled, true
end
