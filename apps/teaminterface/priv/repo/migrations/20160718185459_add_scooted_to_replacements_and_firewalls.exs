defmodule Teaminterface.Repo.Migrations.AddScootedToReplacementsAndFirewalls do
  use Ecto.Migration

  def change do
    alter table(:replacements) do
      add(:scoot, :boolean, null: false, default: false)
    end

    alter table(:firewalls) do
      add(:scoot, :boolean, null: false, default: false)
    end
  end
end
