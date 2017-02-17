use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :teaminterface, Teaminterface.Endpoint,
http: [port: 4000],
https: [port: 4443,
        keyfile: "priv/https/server.key",
        certfile: "priv/https/server.crt",
        cacertfile: "priv/https/ca.crt"
       ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                   cd: Path.expand("../", __DIR__)]]

# Watch static and templates for browser reloading.
config :teaminterface, Teaminterface.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex|haml)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
cond do
  System.get_env("DATABASE_URL") ->
    config :teaminterface, Teaminterface.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: {:system, "DATABASE_URL"}
  true ->
    config :teaminterface, Teaminterface.Repo,
    adapter: Ecto.Adapters.Postgres,
    # username: "postgres",
    # password: "postgres",
    database: "teaminterface_dev",
    hostname: "localhost",
    pool_size: 10
end

config :comeonin,
  bcrypt_log_rounds: 4

config :teaminterface, :upload_root, "/tmp/teaminterface"

config :teaminterface, :download_root, "/tmp/teaminterface"
