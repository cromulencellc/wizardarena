defmodule Teaminterface.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string
      add :shortname, :string
      add :displayname, :string
      add :color, :string
      add :password_digest, :string

      timestamps
    end

  end
end
