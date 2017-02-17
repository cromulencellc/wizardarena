defmodule Teaminterface.Repo.Migrations.CreateRound do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :nickname, :string
      add :started_at, :datetime
      add :finished_at, :datetime

      timestamps
    end
    create unique_index(:rounds, [:nickname])

  end
end
