defmodule Teaminterface.Repo.Migrations.CreateContainerReport do
  use Ecto.Migration

  def change do
    create table(:container_reports) do
      add :replay_seed, :string
      add :polls_passed, :integer
      add :polls_failed, :integer
      add :polls_timed_out, :integer
      add :polls_total, :integer
      add :last_complete_position, :integer
      add :max_position, :integer
      add :team_id, references(:teams, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)

      timestamps
    end
    create index(:container_reports, [:team_id])
    create index(:container_reports, [:round_id])
    create index(:container_reports, [:challenge_set_id])

  end
end
