defmodule Teaminterface.Repo.Migrations.CreateChallengeSetAlias do
  use Ecto.Migration

  def change do
    create table(:challenge_set_aliases) do
      add :cgc_id, :bigint, null: false
      add(:challenge_set_id,
          references(:challenge_sets, on_delete: :nothing),
          null: false)

      timestamps
    end
    create index(:challenge_set_aliases, [:challenge_set_id])

  end
end
