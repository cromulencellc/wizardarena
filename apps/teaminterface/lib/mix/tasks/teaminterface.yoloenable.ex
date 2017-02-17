defmodule Mix.Tasks.Teaminterface.Yoloenable do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Enable all challenge sets for all rounds"

  def run(_args) do
    [repo] = parse_repo([])
    ensure_repo(repo, [])
    {:ok, pid, apps} = ensure_started(repo, [all: true,
                                             pool_size: 1])

    q = """
      INSERT INTO enablements
        (challenge_set_id, round_id, inserted_at, updated_at)
        (SELECT cs.id, r.id, now(), now()
          FROM challenge_sets AS cs
          CROSS JOIN rounds AS r)
        ON CONFLICT DO NOTHING;
        """

    Ecto.Adapters.SQL.query(Teaminterface.Repo, q, [])

    pid && repo.stop(pid)
    restart_apps_if_migrated(apps, [:x])
  end
end
