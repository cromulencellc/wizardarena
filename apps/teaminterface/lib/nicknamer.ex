defmodule Nicknamer do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Nicknamer.NicknameServer, [[name: :nickname_server]])
    ]

    opts = [strategy: :one_for_one, name: Nicknamer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(_changed, _new, _removed) do
    :ok
  end
end
