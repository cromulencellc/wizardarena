defmodule Teaminterface.Repo.Migrations.AddChallengeSetIdToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :challenge_set_id, references(:challenge_sets, on_delete: :nothing)
    end

    create index(:scores,
                 [:team_id, :round_id, :challenge_set_id],
                 unique: true)
  end
end
