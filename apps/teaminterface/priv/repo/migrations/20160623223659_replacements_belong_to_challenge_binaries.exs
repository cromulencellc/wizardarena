defmodule Teaminterface.Repo.Migrations.ReplacementsBelongToChallengeBinaries do
  use Ecto.Migration

  def change do
    alter table(:replacements) do
      remove :challenge_set_id
      remove :filename
      add(:challenge_binary_id,
          references(:challenge_binaries, on_delete: :nothing))
    end

    create index(:replacements, [:challenge_binary_id])
    create index(:replacements,
                 [:team_id, :round_id, :challenge_binary_id],
                 unique: true)
  end
end
