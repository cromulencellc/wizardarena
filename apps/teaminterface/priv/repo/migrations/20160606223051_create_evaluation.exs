defmodule Teaminterface.Repo.Migrations.CreateEvaluation do
  use Ecto.Migration

  def change do
    create table(:evaluations) do
      add :connect, :integer, null: false
      add :success, :integer, null: false
      add :timeout, :integer, null: false
      add :time, :integer, null: false
      add :memory, :integer, null: false
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :round_id, references(:rounds, on_delete: :nothing), null: false
      add(:challenge_set_id,
          references(:challenge_sets, on_delete: :nothing),
          null: false)

      timestamps
    end
    create index(:evaluations, [:team_id])
    create index(:evaluations, [:round_id])
    create index(:evaluations, [:challenge_set_id])
    create index(:evaluations,
                 [:team_id, :round_id, :challenge_set_id],
                 unique: true)
  end
end
