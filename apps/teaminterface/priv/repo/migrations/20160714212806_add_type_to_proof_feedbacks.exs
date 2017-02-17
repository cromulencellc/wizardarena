defmodule Teaminterface.Repo.Migrations.AddTypeToProofFeedbacks do
  use Ecto.Migration

  def change do
    alter table(:proof_feedbacks) do
      add :type, :integer
      add :seed, :binary
    end
  end
end
