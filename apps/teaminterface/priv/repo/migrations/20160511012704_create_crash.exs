defmodule Teaminterface.Repo.Migrations.CreateCrash do
  use Ecto.Migration

  def change do
    create table(:crashes) do
      add :signal, :integer
      add :team_id, references(:teams, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)
      add :challenge_binary_id, references(:challenge_binaries, on_delete: :nothing)

      timestamps
    end
    create index(:crashes, [:team_id])
    create index(:crashes, [:round_id])
    create index(:crashes, [:challenge_binary_id])

  end
end
