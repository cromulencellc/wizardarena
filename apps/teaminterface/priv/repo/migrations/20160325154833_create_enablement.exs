defmodule Teaminterface.Repo.Migrations.CreateEnablement do
  use Ecto.Migration

  def change do
    create table(:enablements) do
      add :round_id, references(:rounds, on_delete: :nothing), null: false
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing), null: false

      timestamps
    end
    create index(:enablements, [:round_id])
    create index(:enablements, [:challenge_set_id])
    create index(:enablements, [:round_id, :challenge_set_id])
  end
end
