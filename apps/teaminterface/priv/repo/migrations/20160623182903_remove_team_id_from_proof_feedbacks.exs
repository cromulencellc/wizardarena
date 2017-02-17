defmodule Teaminterface.Repo.Migrations.RemoveTeamIdFromProofFeedbacks do
  use Ecto.Migration

  def change do
    alter table(:proof_feedbacks) do
      remove :team_id
    end
  end
end
