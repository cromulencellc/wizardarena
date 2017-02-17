defmodule Teaminterface.Repo.Migrations.AddScoreToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add(:score, :float, null: false, default: 31337)
    end
  end
end
