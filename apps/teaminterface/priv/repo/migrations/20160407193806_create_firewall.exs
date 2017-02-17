defmodule Teaminterface.Repo.Migrations.CreateFirewall do
  use Ecto.Migration

  def change do
    create table(:firewalls) do
      add :digest, :string
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :round_id, references(:rounds, on_delete: :nothing), null: false
      add(:challenge_set_id,
          references(:challenge_sets, on_delete: :nothing),
          null: false)

      timestamps
    end
    create index(:firewalls, [:team_id])
    create index(:firewalls, [:round_id])
    create index(:firewalls, [:challenge_set_id])
    create index(:firewalls,
                 [:team_id, :round_id, :challenge_set_id],
                 unique: true)

  end
end
