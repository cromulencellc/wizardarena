defmodule Teaminterface.Repo.Migrations.CreatePollFeedbackAgain do
  use Ecto.Migration

  def change do
    create table(:poll_feedbacks) do
      add :wall_time, :float
      add :max_rss, :integer
      add :min_flt, :integer
      add :utime, :float
      add :task_clock, :integer
      add :cpu_clock, :integer
      add :status, :string
      add :team_id, references(:teams, on_delete: :nothing)
      add :poller_id, references(:pollers, on_delete: :nothing)

      timestamps
    end
    create index(:poll_feedbacks, [:team_id])
    create index(:poll_feedbacks, [:poller_id])

  end
end
