defmodule Teaminterface.Repo.Migrations.CreateProofFeedbackAgain do
  use Ecto.Migration

  def change do
    create table(:proof_feedbacks) do
      add :throw, :integer
      add :successful, :boolean, default: false
      add :error, :string
      add :signal, :integer
      add :proof_id, references(:proofs, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)
      add :team_id, references(:teams, on_delete: :nothing)

      timestamps
    end
    create index(:proof_feedbacks, [:proof_id])
    create index(:proof_feedbacks, [:round_id])
    create index(:proof_feedbacks, [:team_id])

  end
end
