defmodule Teaminterface.Repo.Migrations.AddPatchedSizeToChallengeBinaries do
  use Ecto.Migration

  def change do
    alter table(:challenge_binaries) do
      add :patched_size, :integer, null: false, default: 0
    end
  end
end
