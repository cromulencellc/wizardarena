defmodule Teaminterface.Repo.Migrations.ReplacmentsFilenameIndex do
  use Ecto.Migration

  def change do
    drop index(:replacements,
                 [:team_id, :round_id, :challenge_set_id],
                 unique: true)

    create index(:replacements,
                 [:team_id, :round_id, :challenge_set_id, :filename],
                 unique: true)
  end
end
