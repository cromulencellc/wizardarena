defmodule Teaminterface.Repo.Migrations.CreateReplacement do
  use Ecto.Migration

  def change do
    create table(:replacements) do
      add :filename, :string
      add :digest, :string
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :round_id, references(:rounds, on_delete: :nothing), null: false
      add(:challenge_set_id,
          references(:challenge_sets, on_delete: :nothing),
          null: false)

      timestamps
    end
    create index(:replacements, [:team_id])
    create index(:replacements, [:round_id])
    create index(:replacements, [:challenge_set_id])
    create index(:replacements,
                 [:team_id, :round_id, :challenge_set_id],
                 unique: true)
  end
end
