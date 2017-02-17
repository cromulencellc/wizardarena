defmodule Teaminterface.Repo.Migrations.CreateProof do
  use Ecto.Migration

  def change do
    create table(:proofs) do
      add :digest, :string
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :round_id, references(:rounds, on_delete: :nothing), null: false
      add(:challenge_set_id,
          references(:challenge_sets, on_delete: :nothing),
          null: false)
      add :target_id, references(:teams, on_delete: :nothing)
      add :throws, :integer

      timestamps
    end
    create index(:proofs, [:team_id])
    create index(:proofs, [:round_id])
    create index(:proofs, [:challenge_set_id])
    create index(:proofs, [:target_id])
    create index(:proofs,
                 [:team_id, :round_id, :challenge_set_id, :target_id],
                 unique: true)
  end
end
