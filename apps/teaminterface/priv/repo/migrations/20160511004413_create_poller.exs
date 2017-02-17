defmodule Teaminterface.Repo.Migrations.CreatePoller do
  use Ecto.Migration

  def change do
    create table(:pollers) do
      add :seed, :binary
      add :mean_wall_time, :float
      add :stddev_wall_time, :float
      add :mean_max_rss, :float
      add :stddev_max_rss, :float
      add :mean_min_flt, :float
      add :stddev_min_flt, :float
      add :mean_utime, :float
      add :stddev_utime, :float
      add :mean_task_clock, :float
      add :stddev_task_clock, :float
      add :mean_cpu_clock, :float
      add :stddev_cpu_clock, :float
      add :round_id, references(:rounds, on_delete: :nothing)
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)

      timestamps
    end
    create index(:pollers, [:round_id])
    create index(:pollers, [:challenge_set_id])

  end
end
