defmodule Teaminterface.Repo.Migrations.CreateProofFeedback do
  use Ecto.Migration

  def change do
    create table(:proof_feedbacks) do
      add :team_id, references(:teams, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)

      timestamps
    end
    create index(:proof_feedbacks, [:team_id])
    create index(:proof_feedbacks, [:round_id])
    create index(:proof_feedbacks, [:challenge_set_id])

  end
end
