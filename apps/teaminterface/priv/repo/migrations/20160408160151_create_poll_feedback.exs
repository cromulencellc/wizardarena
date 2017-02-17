defmodule Teaminterface.Repo.Migrations.CreatePollFeedback do
  use Ecto.Migration

  def change do
    create table(:poll_feedbacks) do
      add :team_id, references(:teams, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)

      timestamps
    end
    create index(:poll_feedbacks, [:team_id])
    create index(:poll_feedbacks, [:round_id])
    create index(:poll_feedbacks, [:challenge_set_id])

  end
end
