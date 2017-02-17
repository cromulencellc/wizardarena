defmodule Teaminterface.Repo.Migrations.AddRngSeeds do
  use Ecto.Migration

  def change do
    alter table(:rounds) do
      add(:secret, :binary)
      add(:seed, :binary, null: false)
    end
  end
end
