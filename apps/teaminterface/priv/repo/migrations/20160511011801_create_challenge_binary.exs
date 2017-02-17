defmodule Teaminterface.Repo.Migrations.CreateChallengeBinary do
  use Ecto.Migration

  def change do
    create table(:challenge_binaries) do
      add :index, :integer
      add :size, :integer
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)

      timestamps
    end

    create index(:challenge_binaries, [:challenge_set_id])
  end
end
