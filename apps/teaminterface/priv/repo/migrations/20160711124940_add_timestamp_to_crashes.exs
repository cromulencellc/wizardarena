defmodule Teaminterface.Repo.Migrations.AddTimestampToCrashes do
  use Ecto.Migration

  def change do
    alter table(:crashes) do
      add :timestamp, :datetime, null: false
    end
  end
end
