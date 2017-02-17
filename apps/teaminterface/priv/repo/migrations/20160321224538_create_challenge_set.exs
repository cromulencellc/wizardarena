defmodule Teaminterface.Repo.Migrations.CreateChallengeSet do
  use Ecto.Migration

  def change do
    create table(:challenge_sets) do
      add :name, :string, null: false
      add :shortname, :string, null: false

      timestamps
    end

    create index(:challenge_sets, [:shortname], unique: true)
  end
end
