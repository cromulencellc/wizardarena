defmodule Teaminterface.Repo.Migrations.AddFileIdToPollers do
  use Ecto.Migration

  def change do
    alter table(:pollers) do
      add(:file_id, :integer)
    end
  end
end
