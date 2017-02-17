defmodule Teaminterface.Repo.Migrations.AddSizeToReplacements do
  use Ecto.Migration

  def change do
    alter table(:replacements) do
      add(:size, :integer, null: false, default: 0)
    end
  end
end
