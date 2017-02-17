defmodule Teaminterface.Repo.Migrations.CreateScore do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :security, :integer
      add :availability, :float
      add :evaluation, :float
      add :team_id, references(:teams, on_delete: :nothing)
      add :round_id, references(:rounds, on_delete: :nothing)

      timestamps
    end
    create index(:scores, [:team_id])
    create index(:scores, [:round_id])

  end
end
